###
# All linux platforms
###

locals {
  os = "linux"
  role_tag = {
    "Name" = "${var.globals.cluster_name}-${var.role}"
    "Role" = var.role
  }
  tags = merge(
    var.globals.tags,
    local.role_tag
  )
  tags_nokube = merge(
    var.globals.tags_nokube,
    local.role_tag
  )
  role_platform    = var.globals.role_platform
  default_platform = var.globals.default_platform
  platform = coalesce(
    local.role_platform[var.role],
    local.default_platform[local.os]
  )
  distro = split("_", local.platform)[0]
  scripts_dir       = "${path.module}/../scripts"
  base_linux_script = "${local.scripts_dir}/user_data_linux.sh"

  platform_script = fileexists(
    "${local.scripts_dir}/user_data_${local.platform}.sh"
    ) ? (
      "${local.scripts_dir}/user_data_${local.platform}.sh"
    ) : (
      "${local.scripts_dir}/user_data_default.sh"
  )

  final_linux_script = "${local.scripts_dir}/user_data_linux_final.sh"
}

# get image ID from platform name
module "ami" {
  source   = "../ami"
  platform = local.platform
}

data "template_file" "distro_script" {
  template = (
    file(
      "${local.scripts_dir}/user_data_${local.distro}.sh"
    )
  )
  vars = {
    # future use
  }
}

data "cloudinit_config" "linux" {
  part {
    content_type = "text/x-shellscript"
    content      = file(local.base_linux_script)
    filename     = "baselinux.sh"
  }
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.distro_script.rendered
    filename     = "distro.sh"
  }
  part {
    content_type = "text/x-shellscript"
    content      = file(local.platform_script)
    filename     = "platform.sh"
  }
  part {
    content_type = "text/x-shellscript"
    content      = file(local.final_linux_script)
    filename     = "final.sh"
  }
}

locals {
  node_ids  = var.life_cycle == "spot" ? module.spot.node_ids : module.ondemand.node_ids
  instances = var.life_cycle == "spot" ? module.spot.instances : module.ondemand.instances
}

module "spot" {
  source        = "../spot"
  globals       = var.globals
  node_count    = var.life_cycle == "spot" ? var.node_count : 0
  image_id      = module.ami.image_id
  instance_type = var.instance_type
  volume_size   = var.volume_size
  tags          = local.tags
  user_data     = data.cloudinit_config.linux.rendered
}

module "ondemand" {
  source        = "../ondemand"
  globals       = var.globals
  node_count    = var.life_cycle == "ondemand" ? var.node_count : 0
  image_id      = module.ami.image_id
  instance_type = var.instance_type
  volume_size   = var.volume_size
  tags          = local.tags
  user_data     = data.cloudinit_config.linux.rendered
}

# Verify node Ready state post-cloud-init
# @NOTE Remote ssh into each node and verify that cloud-init
#    has completed, prior to concluding terraform run.
#    Safeguards against launchpad starting prior to user-init
#    completing.
resource "null_resource" "cluster" {
  triggers = {
    cluster_instance_ids = join(",", local.node_ids)
  }
  count = length(local.instances)

  connection {
    type        = "ssh"
    host        = local.instances[count.index].public_ip
    user        = module.ami.user
    private_key = file(var.globals.key_path)
    agent       = false
  }
  provisioner "remote-exec" {
    script = "${path.module}/../scripts/wait_until_ready.sh"
  }
}
