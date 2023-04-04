###
# Windows platforms only
###

locals {
  os = "windows"
  tag_role = {
    "Name"     = "${var.globals.cluster_name}-win-${var.role}"
    "Role"     = var.role
    "platform" = local.platform
  }
  tags = merge(
    var.globals.tags,
    local.tag_role
  )
  tags_nokube = merge(
    var.globals.tags_nokube,
    local.tag_role
  )
  platform = var.globals.default_platform[local.os]
}

module "ami" {
  source   = "../ami"
  platform = local.platform
}

data "template_file" "windows" {
  template = file("${path.module}/../templates/user_data_windows.tpl")
  vars = {
    win_admin_password = var.win_admin_password
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
  user_data     = base64encode(data.template_file.windows.rendered)
}

module "ondemand" {
  source        = "../ondemand"
  globals       = var.globals
  node_count    = var.life_cycle == "ondemand" ? var.node_count : 0
  image_id      = module.ami.image_id
  instance_type = var.instance_type
  volume_size   = var.volume_size
  tags          = local.tags
  user_data     = base64encode(data.template_file.windows.rendered)
}

resource "null_resource" "cluster" {
  triggers = {
    cluster_instance_ids = join(",", local.node_ids)
  }
  count = length(local.instances)

  provisioner "remote-exec" {
    connection {
      host     = local.instances[count.index].public_ip
      type     = "winrm"
      user     = module.ami.user
      password = var.win_admin_password
      timeout  = "10m"
      https    = "true"
      insecure = "true"
      port     = 5986
    }
    inline = [
      "echo hello"
    ]
  }
}
