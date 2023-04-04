##### Worker nodes => Istio ingress port ########
resource "openstack_lb_loadbalancer_v2" "lb_worker" {
  name = "${var.cluster_name}-worker-lb"
  vip_subnet_id = var.internal_subnet_id
}

resource "openstack_lb_listener_v2" "lb_list_worker" {
  protocol = "TCP"
  name = "${var.cluster_name}-worker-listener"
  protocol_port = 33000
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_worker.id
}

resource "openstack_lb_pool_v2" "lb_pool_worker" {
  protocol = "TCP"
  name = "${var.cluster_name}-worker-pool"
  lb_method = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.lb_list_worker.id
}

resource "openstack_lb_member_v2" "lb_member_worker" {
  count = var.worker_count
  pool_id = openstack_lb_pool_v2.lb_pool_worker.id
  protocol_port = 33000
  address = element(openstack_compute_instance_v2.docker-worker.*.network.0.fixed_ip_v4, count.index)
  subnet_id = var.internal_subnet_id
}

resource "openstack_networking_floatingip_v2" "worker_lb_vip" {
  pool              = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "worker_vip" {
  floating_ip = openstack_networking_floatingip_v2.worker_lb_vip.address
  port_id = openstack_lb_loadbalancer_v2.lb_worker.vip_port_id
}

