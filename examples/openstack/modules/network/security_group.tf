resource "openstack_networking_secgroup_v2" "docker-base" {
  name = "${var.cluster_name}-base"
  description = "Open all external TCP ports to worker nodes"
}

#TODO: check if necessarry (Istio)
resource "openstack_networking_secgroup_rule_v2" "docker-base-ssh" {
  direction = "ingress"
  ethertype = "IPv4"
  port_range_min = 22
  port_range_max = 22
  protocol = "tcp"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}

resource "openstack_networking_secgroup_rule_v2" "docker-base-int-all-tcp" {
  direction = "ingress"
  ethertype = "IPv4"
  port_range_min = 1
  port_range_max = 65535
  protocol = "tcp"
  remote_ip_prefix = openstack_networking_subnet_v2.docker-int-subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}

resource "openstack_networking_secgroup_rule_v2" "docker-base-int-icmp" {
  direction = "ingress"
  ethertype = "IPv4"
  port_range_min = 1
  port_range_max = 1
  protocol = "icmp"
  remote_ip_prefix = openstack_networking_subnet_v2.docker-int-subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}


resource "openstack_networking_secgroup_rule_v2" "docker-base-int-icmp-out" {
  direction = "egress"
  ethertype = "IPv4"
  port_range_min = 1
  port_range_max = 1
  protocol = "icmp"
  remote_ip_prefix = openstack_networking_subnet_v2.docker-int-subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}
resource "openstack_networking_secgroup_rule_v2" "docker-base-int-all-udp" {
  direction = "ingress"
  ethertype = "IPv4"
  port_range_min = 1
  port_range_max = 65535
  protocol = "udp"
  remote_ip_prefix = openstack_networking_subnet_v2.docker-int-subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}


resource "openstack_networking_secgroup_rule_v2" "default_ipv4_encupsulation" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "4"
  remote_ip_prefix = openstack_networking_subnet_v2.docker-int-subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.docker-base.id
}

