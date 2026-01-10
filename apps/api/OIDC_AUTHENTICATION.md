# OIDC Authentication Guide

## Overview

This guide explains how to implement OIDC (OpenID Connect) authentication in the frontend. The backend supports any OIDC-compliant provider (including Keycloak, Auth0, Okta, etc.).

## Authentication Flow

### 1. Initiate OIDC Login

Redirect the user to the OIDC initiation endpoint:

```
GET /auth/oidc/?next_path=<optional_redirect_path>
```

**Query Parameters:**

- `next_path` (optional): URL path to redirect to after successful authentication (e.g., `/dashboard`, `/workspaces`)

**Example:**

```javascript
// Redirect user to OIDC login
window.location.href = "/auth/oidc/?next_path=/dashboard";
```

**What happens:**

1. Backend generates a state token and stores it in the session
2. Backend redirects user to the OIDC provider's authorization endpoint
3. User authenticates with the OIDC provider

### 2. OIDC Callback

After authentication, the OIDC provider redirects back to:

```
GET /auth/oidc/callback/?code=<authorization_code>&state=<state_token>
```

**What happens:**

1. Backend validates the state token
2. Backend exchanges the authorization code for tokens
3. Backend fetches user information from OIDC provider
4. Backend creates or logs in the user
5. Backend redirects to the `next_path` (or default path if not provided)

**Success Response:**

- Redirects to the `next_path` or default user dashboard
- User is now authenticated (session cookie is set)

**Error Response:**

- Redirects to the frontend with error parameters:
  - `error_code`: Error code (e.g., `5124` for `OIDC_OAUTH_PROVIDER_ERROR`)
  - `error_message`: Error message (e.g., `OIDC_OAUTH_PROVIDER_ERROR`)

## Implementation Example

### React/Next.js Example

```javascript
// Initiate OIDC login
const handleOIDCLogin = (nextPath = "/dashboard") => {
  window.location.href = `/auth/oidc/?next_path=${encodeURIComponent(nextPath)}`;
};

// Usage
<button onClick={() => handleOIDCLogin("/workspaces")}>Login with OIDC</button>;
```

### Vanilla JavaScript Example

```javascript
function loginWithOIDC(nextPath) {
  const url = `/auth/oidc/${nextPath ? `?next_path=${encodeURIComponent(nextPath)}` : ""}`;
  window.location.href = url;
}
```

## Error Handling

The callback endpoint may redirect with error parameters. Handle them in your frontend:

```javascript
// Check for errors in URL parameters
const urlParams = new URLSearchParams(window.location.search);
const errorCode = urlParams.get("error_code");
const errorMessage = urlParams.get("error_message");

if (errorCode) {
  // Handle error
  console.error("OIDC Authentication Error:", errorCode, errorMessage);
  // Display error message to user
}
```

### Common Error Codes

- `5000` - `INSTANCE_NOT_CONFIGURED`: Backend instance is not properly configured
- `5113` - `OIDC_NOT_CONFIGURED`: OIDC is not configured in the backend
- `5124` - `OIDC_OAUTH_PROVIDER_ERROR`: Error during OIDC authentication flow

## Space Authentication

For space-specific authentication (multi-tenant scenarios), use:

```
GET /auth/spaces/oidc/?next_path=<optional_redirect_path>
```

The callback endpoint is:

```
GET /auth/spaces/oidc/callback/?code=<authorization_code>&state=<state_token>
```

## Important Notes

1. **State Management**: The backend automatically handles state token generation and validation for security.

2. **Session Cookies**: After successful authentication, the backend sets a session cookie. Ensure your frontend can handle cookies.

3. **Redirect URI**: The redirect URI is automatically constructed as `{BACKEND_URL}/auth/oidc/callback/`. This must match what's configured in your OIDC provider.

4. **CORS**: If your frontend and backend are on different domains, ensure CORS is properly configured.

## Testing

1. Test the initiation endpoint: `GET /auth/oidc/`
2. Complete the OIDC authentication flow
3. Verify the callback redirects correctly
4. Check that the user session is established
