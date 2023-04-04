locals {

 docker-int-net = {
    name = "${var.cluster_name}-int-net"
    subnet_name = "${var.cluster_name}-net-sub01",
    cidr = var.cidr
  }
}

resource "openstack_networking_router_v2" "generic" {
  name                = "${var.cluster_name}-router"
  external_network_id = var.external_network_id
}

resource "openstack_networking_network_v2" "docker-int" {
  name                = local.docker-int-net["name"]
}

resource "openstack_networking_subnet_v2" "docker-int-subnet" {
  name                = local.docker-int-net["subnet_name"]
  network_id          = openstack_networking_network_v2.docker-int.id
  cidr                = local.docker-int-net["cidr"]
  dns_nameservers     = var.dns_ips
}

resource "openstack_networking_router_interface_v2" "docker-int" {
  router_id           = openstack_networking_router_v2.generic.id
  subnet_id           = openstack_networking_subnet_v2.docker-int-subnet.id
}

