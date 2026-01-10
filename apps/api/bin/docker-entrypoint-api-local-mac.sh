#!/bin/bash
set -e

# Wait for database and migrations
python manage.py wait_for_db
python manage.py wait_for_migrations

# ==============================
# Collect system information
# ==============================

HOSTNAME=$(hostname)

# MAC address (first active interface)
MAC_ADDRESS=$(ifconfig | awk '/ether/{print $2}' | head -n 1)

# CPU information (macOS)
CPU_INFO=$(sysctl -n machdep.cpu.brand_string)

# Memory information (macOS)
MEMORY_INFO=$(top -l 1 | grep PhysMem)

# Disk information (portable)
DISK_INFO=$(df -h)

# ==============================
# Generate machine signature
# ==============================

SIGNATURE=$(echo "$HOSTNAME$MAC_ADDRESS$CPU_INFO$MEMORY_INFO$DISK_INFO" \
  | shasum -a 256 \
  | awk '{print $1}')

export MACHINE_SIGNATURE="$SIGNATURE"

# ==============================
# Application setup
# ==============================

# Register instance
python manage.py register_instance "$MACHINE_SIGNATURE"

# Load configuration
python manage.py configure_instance

# Create the default bucket
python manage.py create_bucket

# Clear cache to remove stale values
python manage.py clear_cache

# Start development server
python manage.py runserver 0.0.0.0:8000 --settings=plane.settings.local