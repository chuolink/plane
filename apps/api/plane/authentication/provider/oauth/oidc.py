# Python imports
import os
from datetime import datetime, timedelta
from urllib.parse import urlencode, urljoin

import pytz
import requests

# Module imports
from plane.authentication.adapter.oauth import OauthAdapter
from plane.license.utils.instance_value import get_configuration_value
from plane.authentication.adapter.error import (
    AUTHENTICATION_ERROR_CODES,
    AuthenticationException,
)


class OIDCOAuthProvider(OauthAdapter):
    provider = "oidc"
    default_scope = "openid profile email"

    def __init__(self, request, code=None, state=None, callback=None):
        (OIDC_ISSUER_URL, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET, OIDC_SCOPE, BACKEND_URL) = get_configuration_value(
            [
                {
                    "key": "OIDC_ISSUER_URL",
                    "default": os.environ.get("OIDC_ISSUER_URL"),
                },
                {
                    "key": "OIDC_CLIENT_ID",
                    "default": os.environ.get("OIDC_CLIENT_ID"),
                },
                {
                    "key": "OIDC_CLIENT_SECRET",
                    "default": os.environ.get("OIDC_CLIENT_SECRET"),
                },
                {
                    "key": "OIDC_SCOPE",
                    "default": os.environ.get("OIDC_SCOPE", self.default_scope),
                },
                {
                    "key": "BACKEND_URL",
                    "default": os.environ.get("BACKEND_URL"),
                },
            ]
        )

        if not (OIDC_ISSUER_URL and OIDC_CLIENT_ID and OIDC_CLIENT_SECRET):
            raise AuthenticationException(
                error_code=AUTHENTICATION_ERROR_CODES["OIDC_NOT_CONFIGURED"],
                error_message="OIDC_NOT_CONFIGURED",
            )

        # Normalize issuer URL (remove trailing slash)
        issuer_url = OIDC_ISSUER_URL.rstrip("/")
        client_id = OIDC_CLIENT_ID
        client_secret = OIDC_CLIENT_SECRET
        scope = OIDC_SCOPE or self.default_scope

        # Construct OIDC endpoints
        # Note: urljoin treats paths starting with / as absolute, so we need to ensure proper joining
        # If issuer_url doesn't end with /, urljoin will replace the path. So we append without leading slash.
        auth_url = urljoin(issuer_url + "/", "protocol/openid-connect/auth")
        token_url = urljoin(issuer_url + "/", "protocol/openid-connect/token")
        userinfo_url = urljoin(issuer_url + "/", "protocol/openid-connect/userinfo")

        # Use configured backend URL or fall back to request-based URL
        if BACKEND_URL:
            base_url = BACKEND_URL.rstrip("/")
            redirect_uri = f"{base_url}/auth/oidc/callback"
        else:
            # Fallback to request-based URL if not configured
            redirect_uri = f"""{"https" if request.is_secure() else "http"}://{request.get_host()}/auth/oidc/callback"""
        url_params = {
            "client_id": client_id,
            "scope": scope,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "state": state,
        }
        auth_url_with_params = f"{auth_url}?{urlencode(url_params)}"

        super().__init__(
            request,
            self.provider,
            client_id,
            scope,
            redirect_uri,
            auth_url_with_params,
            token_url,
            userinfo_url,
            client_secret,
            code,
            callback=callback,
        )

    def set_token_data(self):
        data = {
            "code": self.code,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "redirect_uri": self.redirect_uri,
            "grant_type": "authorization_code",
        }
        token_response = self.get_user_token(data=data)
        super().set_token_data(
            {
                "access_token": token_response.get("access_token"),
                "refresh_token": token_response.get("refresh_token", None),
                "access_token_expired_at": (
                    datetime.now(tz=pytz.utc) + timedelta(seconds=token_response.get("expires_in", 3600))
                    if token_response.get("expires_in")
                    else None
                ),
                "refresh_token_expired_at": (
                    datetime.fromtimestamp(token_response.get("refresh_token_expired_at"), tz=pytz.utc)
                    if token_response.get("refresh_token_expired_at")
                    else None
                ),
                "id_token": token_response.get("id_token", ""),
            }
        )

    def set_user_data(self):
        user_info_response = self.get_user_response()
        # OIDC standard claims
        email = user_info_response.get("email")
        # If email is not provided, try preferred_username (some providers use this)
        if not email:
            email = user_info_response.get("preferred_username")
        # Note: If email is still not found, sanitize_email in base adapter will raise an error
        
        first_name = user_info_response.get("given_name") or user_info_response.get("first_name") or ""
        last_name = user_info_response.get("family_name") or user_info_response.get("last_name") or ""
        picture = user_info_response.get("picture") or user_info_response.get("avatar")
        provider_id = user_info_response.get("sub") or user_info_response.get("id")

        user_data = {
            "email": email,
            "user": {
                "avatar": picture,
                "first_name": first_name,
                "last_name": last_name,
                "provider_id": provider_id,
                "is_password_autoset": True,
            },
        }
        super().set_user_data(user_data)
