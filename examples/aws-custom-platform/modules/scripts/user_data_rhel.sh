#!/bin/bash
# This script will be executed user_data_linux.sh
# and before the platform-specific script during deployment

# RHEL customization

# Disable subscription manager on applicable systems
# https://sahlitech.com/entitlement-server-fix/
SUBMGRCONF="/etc/yum/pluginconf.d/subscription-manager.conf"
[ -f $SUBMGRCONF ] && sed -i -e "s|^enabled=.*|enabled=0|" $SUBMGRCONF

# Prep for NFS mount (MSR 2.x prerequisites)
yum install -y nfs-utils
