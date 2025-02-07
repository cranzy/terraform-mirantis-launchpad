provider "aws" {
  region = var.aws_region
  shared_credentials_files = [var.aws_shared_credentials_file]
  profile = var.aws_profile
}

module "vpc" {
  source       = "./modules/vpc"
  cluster_name = var.cluster_name
  host_cidr    = var.vpc_cidr
}

module "common" {
  source       = "./modules/common"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.id
}

module "masters" {
  source                = "./modules/master"
  master_count          = var.master_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  master_type           = var.master_type
  master_volume_size    = var.master_volume_size
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  instance_profile_name = module.common.instance_profile_name
}

module "msrs" {
  source                = "./modules/msr"
  msr_count             = var.msr_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  msr_type              = var.msr_type
  msr_volume_size       = var.msr_volume_size
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  instance_profile_name = module.common.instance_profile_name
}

module "workers" {
  source                = "./modules/worker"
  worker_count          = var.worker_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  worker_type           = var.worker_type
  worker_volume_size    = var.worker_volume_size
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  instance_profile_name = module.common.instance_profile_name
}

module "windows_workers" {
  source                         = "./modules/windows_worker"
  worker_count                   = var.windows_worker_count
  vpc_id                         = module.vpc.id
  cluster_name                   = var.cluster_name
  subnet_ids                     = module.vpc.public_subnet_ids
  security_group_id              = module.common.security_group_id
  image_id                       = module.common.windows_2019_image_id
  worker_type                    = var.worker_type
  worker_volume_size             = var.worker_volume_size
  kube_cluster_tag               = module.common.kube_cluster_tag
  instance_profile_name          = module.common.instance_profile_name
  windows_administrator_password = var.windows_administrator_password
}

locals {
  managers = [
    for host in module.masters.machines : {
      ssh = {
        address = host.public_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]
  msrs = [
    for host in module.msrs.machines : {
      ssh = {
        address = host.public_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]
  workers = [
    for host in module.workers.machines : {
      ssh = {
        address = host.public_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]
  windows_workers = [
    for host in module.windows_workers.machines : {
      winRM = {
        address = host.public_ip
        user     = "Administrator"
        password = var.windows_administrator_password
        useHTTPS = true
        insecure = true
      }
      role             = host.tags["Role"]
      privateInterface = "Ethernet 2"
    }
  ]

  mke_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        version       = var.mke_version
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.masters.lb_dns_name}",
        ]
      }
      msr = {}
      hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }


  msr_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke+msr"
    spec = {
      mke = {
        version       = var.mke_version
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.masters.lb_dns_name}",
        ]
      }
      msr = {
        installFlags : [
          "--ucp-insecure-tls",
          "--dtr-external-url ${module.msrs.lb_dns_name}",
        ]
        }
    hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }

  launchpad_tmpl = var.msr_count > 0 ? local.msr_launchpad_tmpl : local.mke_launchpad_tmpl
}


output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}


output "hosts" {
  value = concat(local.managers, local.msrs, local.workers, local.windows_workers)
  description = "All hosts in the cluster"
}

output "mke_lb" {
  value = module.masters.lb_dns_name
  description = "LB path for the MKE ingress"
}

output "msr_lb" {
  value = module.msrs.lb_dns_name
  description = "LB path for the MSR ingress"
}

