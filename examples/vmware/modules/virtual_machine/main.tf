resource "vsphere_virtual_machine" "vm" {
    count = var.quantity

    name = "${var.name_prefix}${count.index}"
    resource_pool_id = var.resource_pool_id
    datastore_cluster_id = var.datastore_cluster_id

    folder = var.folder

    guest_id = var.template_vm.guest_id

    network_interface {
        network_id = var.network_id
    }

    disk {
        label            = "${var.name_prefix}${count.index}"
        size             = var.disk_size
        thin_provisioned = var.template_vm.disks.0.thin_provisioned
    }

    clone {
        template_uuid = var.template_vm.id

        customize {
            network_interface{}

            # Hmm, the linux and windows options might make it tricky to have
            # a single module for handling virtual machines.
            linux_options {
                host_name = "${var.name_prefix}${count.index}"
                domain    = "test.internal"
            }
        }
    }
}
