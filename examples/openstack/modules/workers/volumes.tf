resource "openstack_blockstorage_volume_v2" "worker" {
  count = var.worker_count
  name = "${var.cluster_name}-worker-volume-${count.index}"
  size = var.worker_volume_size
}

resource "openstack_compute_volume_attach_v2" "worker" {
  count       = var.worker_count
  instance_id = element(openstack_compute_instance_v2.docker-worker.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.worker.*.id, count.index)
}
