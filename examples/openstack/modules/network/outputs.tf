output "base_security_group_id" {
  value = openstack_networking_secgroup_v2.docker-base.id
}

output "subnet_id" {
  value = openstack_networking_subnet_v2.docker-int-subnet.id
}

output "network_name" {
  value = openstack_networking_network_v2.docker-int.name
}


