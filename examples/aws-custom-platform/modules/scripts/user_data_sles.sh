#!/bin/bash
# This script will be executed user_data_linux.sh
# and before the platform-specific script during deployment

# SLES customization

# Prep for NFS mount (MSR 2.x prerequisites)
zypper --non-interactive install nfs-client
