#!/bin/bash
# This script will be appended to user_data_linux.sh during deployment
# NOTE: Terraform templates use '$$' to escape '$'

# Oracle 7.9 customization

# Prevent early logins until after new kernel is installed and reboot is executed
systemctl stop sshd

# Replace UEK kernel with RHCK kernel
# install RHCK kernel
yum -y install kernel
# set grub to default to RHCK
grub2-set-default 1
# update grub config
grub2-mkconfig -o /boot/grub2/grub.cfg

# Ensure correct ports are open
# define contiguous range of ports for inclusion
PORT_RANGE=$(for p in {12376..12390} ; do echo "$p/tcp" ; done)
# define all ports, including prior list
PORTS=(
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
)
# add port rules to firewall
for port in ${PORTS[@]} ; do
    firewall-cmd --permanent --add-port=${port}
done
# reload firewall rules
firewall-cmd --reload

# reboot doesn't play nicely with Oracle/terraform
# so run shutdown-reboot after 1m
shutdown -r +1
