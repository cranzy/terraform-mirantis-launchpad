#!/bin/bash
# This script will be executed user_data_linux.sh
# and before the platform-specific script during deployment

# Ubuntu customization

# Prep for NFS mount (MSR 2.x prerequisites)
echo "Running 'apt update -y'"
apt update -y
echo "Running 'apt install -y nfs-common'"
apt install -y nfs-common
