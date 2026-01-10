#!/bin/bash

# Script to create a god-mode admin user in Plane
# Usage: ./create_admin.sh

set -e

echo "=== Plane God-Mode Admin Creation ==="
echo ""

# Get user input
read -p "Email: " EMAIL
read -p "First Name: " FIRST_NAME
read -sp "Password: " PASSWORD
echo ""
read -sp "Password (again): " PASSWORD_CONFIRM
echo ""
read -p "Last Name (optional): " LAST_NAME
read -p "Company Name (optional): " COMPANY_NAME

# Validate inputs
if [ -z "$EMAIL" ]; then
    echo "Error: Email is required"
    exit 1
fi

if [ -z "$FIRST_NAME" ]; then
    echo "Error: First name is required"
    exit 1
fi

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Error: Passwords don't match"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "Error: Password cannot be blank"
    exit 1
fi

# Create Python script to run in Django shell
python3 << EOF
import os
import sys
import django
import uuid
from django.core.validators import validate_email
from django.core.exceptions import ValidationError
from django.contrib.auth.hashers import make_password
from django.utils import timezone
from zxcvbn import zxcvbn

# Setup Django (matching manage.py logic)
debug = os.environ.get("DEBUG", "0") == "1"
if debug:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "plane.settings.local")
else:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "plane.settings.production")
django.setup()

from plane.license.models import Instance, InstanceAdmin
from plane.db.models import User, Profile

# Validate email
email = "$EMAIL".strip().lower()
try:
    validate_email(email)
except ValidationError:
    print(f"Error: Invalid email address: {email}")
    sys.exit(1)

# Check if user already exists
if User.objects.filter(email=email).exists():
    print(f"Error: User with email {email} already exists.")
    print("Use 'python manage.py create_instance_admin {email}' to make them an admin.")
    sys.exit(1)

# Validate password strength
password = "$PASSWORD"
results = zxcvbn(password)
if results["score"] < 3:
    print("Error: Password is too weak. Please use a stronger password.")
    sys.exit(1)

# Get instance
instance = Instance.objects.first()
if instance is None:
    print("Error: No instance found. Please register an instance first.")
    sys.exit(1)

# Check if admin already exists (matching API behavior)
if InstanceAdmin.objects.first():
    print("Error: An instance admin already exists.")
    print("The API only allows creating the first admin via signup.")
    print("Use 'python manage.py create_instance_admin <email>' to add additional admins.")
    sys.exit(1)

try:
    # Create user (matching API exactly)
    user = User.objects.create(
        first_name="$FIRST_NAME",
        last_name="$LAST_NAME",
        email=email,
        username=uuid.uuid4().hex,
        password=make_password(password),
        is_password_autoset=False,
    )
    
    # Create profile
    Profile.objects.create(user=user, company_name="$COMPANY_NAME")
    
    # Set user active and tracking fields (matching API)
    user.is_active = True
    user.last_active = timezone.now()
    user.last_login_time = timezone.now()
    user.token_updated_at = timezone.now()
    user.save()

    # Register the user as an instance admin (matching API - direct create, not get_or_create)
    instance_admin = InstanceAdmin.objects.create(user=user, instance=instance)
    
    # Make the setup flag True and set instance name (matching API exactly)
    instance.is_setup_done = True
    instance.instance_name = "$COMPANY_NAME"
    instance.is_telemetry_enabled = True
    instance.save()

    print("")
    print("✓ Successfully created god-mode admin user!")
    print(f"  Email: {email}")
    print(f"  Name: $FIRST_NAME $LAST_NAME")
    print(f"  Instance Admin ID: {instance_admin.id}")
    
except Exception as e:
    print(f"Error: Failed to create admin user: {str(e)}")
    # Clean up user if created
    if User.objects.filter(email=email).exists():
        User.objects.filter(email=email).delete()
    sys.exit(1)
EOF
