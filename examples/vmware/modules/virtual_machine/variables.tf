variable "quantity" {
    description = "Number of VMs to create"
}

variable "name_prefix" {
    description = "The name of the VMs will be this plus a counter value"
}

variable "resource_pool_id" {
    description = "ID of the resource pool to create the VMs in"
}

variable "datastore_cluster_id" {
    description = "ID of the datastore cluster to create the VMs in"
}

variable "folder" {
    description = "Subfolder in the datacenter at which to create the VMs"
}

variable "network_id" {
    description = "ID of the network to attach the VMs to"
}

variable "template_vm" {
    description = "The template VM which will be cloned as the base for the new VMs"
}

variable "disk_size" {
    description = "Size of the disk drive for the VMs"
}
