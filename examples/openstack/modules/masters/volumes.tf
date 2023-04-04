resource "openstack_blockstorage_volume_v2" "master" {
  count = var.master_count
  name = "#{var.cluster_name}-master-volume-${count.index}"
  size = var.master_volume_size
}

resource "openstack_compute_volume_attach_v2" "master" {
  count       = var.master_count
  instance_id = element(openstack_compute_instance_v2.docker-master.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.master.*.id, count.index)
}


