#!/bin/bash
# This script will be appended to user_data_linux.sh during deployment
# NOTE: Terraform templates use '$$' to escape '$'

# Oracle 7.9 customization

# Prevent early logins until after new kernel is installed and reboot is executed
systemctl stop sshd

# Replace UEK kernel with RHCK kernel
# install RHCK kernel
yum -y install kernel
# determine which installed kernel is RHCK and get the full path
NEW_KERNEL=$(grubby --info=ALL | grep ^kernel | grep -v 'uek.x86_64' | tr '[="]' ' ' | awk '{print $NF}')
# update grub config to use RHCK
grubby --set-default "${NEW_KERNEL}"

# Ensure correct ports are open
# define contiguous range of ports for inclusion
PORT_RANGE=$(for p in {12376..12390} ; do echo "${p}/tcp" ; done)
# define all ports, including prior list
PORTS="
    179/tcp
    443/tcp
    2376/tcp
    2377/tcp
    4789/udp
    6443/tcp
    6444/tcp
    7946/tcp
    7946/udp
    9099/tcp
    10250/tcp
    ${PORT_RANGE}
"

# add port rules to firewall
for port in ${PORTS[@]} ; do
    echo "Enabling firewall port ${port}"
    firewall-offline-cmd --add-port="${port}"
done

# reboot in order to use the RHCK kernel
# (conveniently starts sshd for us again)
reboot
