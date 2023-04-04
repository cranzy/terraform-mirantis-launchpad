provider "aws" {
  region = var.aws_region
}

resource "random_string" "random" {
  length      = 6
  special     = false
  lower       = false
  min_upper   = 2
  min_numeric = 2
}

resource "time_static" "now" {}

module "vpc" {
  source      = "./modules/vpc"
  host_cidr   = var.vpc_cidr
  global_tags = local.global_tags
}

module "efs" {
  source  = "./modules/efs"
  globals = local.globals
}

module "common" {
  source           = "./modules/common"
  cluster_name     = local.cluster_name
  vpc_id           = module.vpc.id
  ami_obj          = local.ami_obj
  ami_obj_win      = local.ami_obj_win
  key_path         = local.key_path
  ssh_algorithm    = var.ssh_algorithm
  open_sg_for_myip = var.open_sg_for_myip
  controller_port  = local.controller_port
  global_tags      = local.global_tags
}

module "elb_mke" {
  source     = "./modules/elb"
  component  = "mke"
  ports      = [local.controller_port, "6443"]
  node_ids   = local.managers.node_ids
  node_count = var.manager_count
  globals    = local.globals
}

module "elb_msr" {
  source     = "./modules/elb"
  component  = "msr"
  ports      = ["443"]
  node_ids   = local.msrs.node_ids
  node_count = local.msr_count
  globals    = local.globals
}

module "managers" {
  source        = "./modules/linux"
  role          = "manager"
  node_count    = var.manager_count
  instance_type = var.manager_type
  life_cycle    = var.life_cycle
  volume_size   = var.manager_volume_size
  globals       = local.globals
}

module "workers" {
  source        = "./modules/linux"
  role          = "worker"
  node_count    = local.worker_count
  instance_type = var.worker_type
  life_cycle    = var.life_cycle
  volume_size   = var.worker_volume_size
  globals       = local.globals
}

module "msrs" {
  source        = "./modules/linux"
  role          = "msr"
  node_count    = local.msr_count
  instance_type = var.msr_type
  life_cycle    = var.life_cycle
  volume_size   = var.msr_volume_size
  globals       = local.globals
}

module "windows_workers" {
  source             = "./modules/windows"
  role               = "worker"
  node_count         = var.windows_worker_count
  instance_type      = var.worker_type
  life_cycle         = var.life_cycle
  volume_size        = var.win_worker_volume_size
  win_admin_password = var.win_admin_password
  globals            = local.globals
}

# get our (client) id
data "aws_caller_identity" "current" {}

locals {
  cluster_name       = var.cluster_name == "" ? random_string.random.result : var.cluster_name
  expire             = timeadd(time_static.now.rfc3339, var.expire_duration)
  kube_orchestration = var.kube_orchestration ? "--default-node-orchestrator=kubernetes" : ""
  platforms_map      = jsondecode(file("${path.root}/etc/platforms.json"))
  ami_obj            = local.platforms_map[var.platform]
  ami_obj_win        = local.platforms_map[var.win_platform]
  default_platform = {
    "linux"   = var.platform
    "windows" = var.win_platform
  }
  user_id    = data.aws_caller_identity.current.user_id
  account_id = data.aws_caller_identity.current.account_id
  msr_install_flags = concat(
    var.msr_install_flags,
    [try("--dtr-external-url=${local.elb_msr.lb_dns_name}", "")],
  )

  # set MSR version to token value if var.msr_version is empty string
  msr_version_major = var.msr_version == "" ? 999 : tonumber( split(".", var.msr_version)[0] )
  # if msr_version_major >= 3 then:
  # add the msr_count onto worker_count, and set msr_count to 0
  # These changes keep MSR 3+ deployment configs out of launchpad.yaml
  worker_count = local.msr_version_major == 2 ? var.worker_count : var.worker_count + var.msr_count
  msr_count    = local.msr_version_major == 2 ? var.msr_count : 0

  managers        = var.manager_count == [] ? null : module.managers
  workers         = var.worker_count == [] ? null : module.workers
  msrs            = var.msr_count == [] ? null : module.msrs
  windows_workers = var.windows_worker_count == [] ? null : module.windows_workers
  elb_msr         = var.msr_count == 0 ? null : module.elb_msr
  efs = (
    local.msr_count > 0
    ) || (
    local.msr_version_major >= 3
  ) ? module.efs : null

  distro = split("_", var.platform)[0]

  global_tags_nokube = merge(
    { # excludes kube-specific tags
      "Name"      = local.cluster_name
      "project"   = var.project
      "platform"  = var.platform
      "expire"    = local.expire
      "lifecycle" = var.life_cycle
      "user_id"   = local.user_id
      "username"  = var.username
      "task_name" = var.task_name
    },
    var.extra_tags
  )

  global_tags = merge(
    { # kube-specific tags
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    },
    local.global_tags_nokube
  )

  globals = {
    tags_nokube       = local.global_tags_nokube
    tags              = local.global_tags
    distro            = local.distro
    vpc_id            = module.vpc.id
    cluster_name      = local.cluster_name
    subnet_id         = module.vpc.public_subnet_id
    region            = var.aws_region
    security_group_id = module.common.security_group_id
    ssh_key           = local.cluster_name
    key_path          = local.key_path
    instance_profile  = module.common.instance_profile
    project           = var.project
    platform          = var.platform
    win_platform      = var.win_platform
    default_platform  = local.default_platform
    role_platform     = var.role_platform
    expire            = local.expire
    iam_fleet_role    = "arn:aws:iam::${local.account_id}:role/AmazonEC2SpotFleetTaggingRole"
  }

  # convert MKE install flags into a map
  mke_opts = { for f in var.mke_install_flags : trimprefix(element(split("=", f), 0), "--") => element(split("=", f), 1) }
  # discover if there is a controller port override.
  controller_port = try(
    local.mke_opts.controller_port,
    "443"
  )
  # Pick a path for saving the RSA private key
  key_path = var.ssh_key_file_path == "" ? "${path.root}/ssh_keys/${local.cluster_name}.pem" : var.ssh_key_file_path

  # Build a list of all machine hosts used in the cluster.
  # @NOTE This list is a meta structure that contains all of the host info used
  #    to build constructs such as the ansible hosts file, the launchpad yaml
  #    or the PRODENG toolbox config
  #
  hosts_linux = concat(
    var.manager_count == 0 ? [] : [
      for host in local.managers.instances : {
        instance = host
        # ami : local.ami_obj
        role = "manager"
        # @TODO put this into the template, not here
        ssh = {
          address = host.public_ip
          user    = local.managers.user
          keyPath = local.key_path
        }
        hooks = {
          apply = {
            before = var.hooks_apply_before
            after  = var.hooks_apply_after
          }
        }
      }
    ],
    local.worker_count == 0 ? [] : [
      for host in local.workers.instances : {
        instance = host
        # ami : local.ami_obj
        role = "worker"
        # @TODO put this into the template, not here
        ssh = {
          address = host.public_ip
          user    = local.workers.user
          keyPath = local.key_path
        }
        hooks = {
          apply = {
            before = var.hooks_apply_before
            after  = var.hooks_apply_after
          }
        }
      }
    ],
    local.msr_count == 0 ? [] : [
      for host in local.msrs.instances : {
        instance = host
        # ami : local.ami_obj
        role = "msr"
        # @TODO put this into the template, not here
        ssh = {
          address = host.public_ip
          user    = local.msrs.user
          keyPath = local.key_path
        }
        hooks = {
          apply = {
            before = var.hooks_apply_before
            after  = var.hooks_apply_after
          }
        }
      }
    ]
  )
  hosts_win = var.windows_worker_count == 0 ? [] : [
    for host in local.windows_workers.instances : {
      instance = host
      ami : local.ami_obj_win
      role = "worker"
      # @TODO put this into the template, not here
      winrm = {
        address  = host.public_ip
        user     = local.ami_obj_win.user
        password = var.win_admin_password
        useHTTPS = true
        insecure = true
      }
    }
  ]
  hosts = concat(
    local.hosts_linux,
    local.hosts_win
  )

}
