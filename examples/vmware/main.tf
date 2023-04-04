provider "vsphere" {
  version        = "~> 1.21"
  vsphere_server = var.vsphere_server
  user           = var.vsphere_user
  password       = var.vsphere_password

  # Enable this if your vSphere server has a self-signed certificate
  # allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.datastore_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template_vm_linux" {
  name          = var.template_vm_linux
  datacenter_id = data.vsphere_datacenter.dc.id
}

# data "vsphere_virtual_machine" "template_vm_windows" {
#   name          = ""
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

module "managers" {
  source               = "./modules/virtual_machine"
  quantity             = var.quantity_managers
  name_prefix          = "manager"
  resource_pool_id     = data.vsphere_resource_pool.resource_pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder               = var.folder
  network_id           = data.vsphere_network.network.id
  template_vm          = data.vsphere_virtual_machine.template_vm_linux
  disk_size            = 16
}

module "workers" {
  source               = "./modules/virtual_machine"
  quantity             = var.quantity_workers
  name_prefix          = "worker"
  resource_pool_id     = data.vsphere_resource_pool.resource_pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder               = var.folder
  network_id           = data.vsphere_network.network.id
  template_vm          = data.vsphere_virtual_machine.template_vm_linux
  disk_size            = 16
}

# module "workers_windows" {
#   source = "./modules/virtual_machine"
#   quantity = var.quantity_workers_windows
#   name_prefix = "worker"
#   resource_pool_id = data.vsphere_resource_pool.resource_pool.id
#   datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
#   folder = "Launchpad team"
#   network_id = data.vsphere_network.network.id
#   template_vm = data.vsphere_virtual_machine.template_windows
#   disk_size = 16
# }
