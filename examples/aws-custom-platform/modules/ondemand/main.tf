###
# Platform-agnostic spot module
###

locals {
  node_ids = var.node_count == 0 ? [] : data.aws_instances.ondemand.ids
}

resource "aws_instance" "node" {
  count                  = var.node_count
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = var.globals.ssh_key
  subnet_id              = var.globals.subnet_id
  iam_instance_profile   = var.globals.instance_profile.id
  vpc_security_group_ids = [var.globals.security_group_id]
  tags                   = var.tags
  user_data              = var.user_data
  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
  }
}

data "aws_instances" "ondemand" {
  instance_tags        = var.tags
  instance_state_names = ["running", "pending"]
  depends_on           = [aws_instance.node]
}

data "aws_instance" "instance" {
  count       = var.node_count
  instance_id = data.aws_instances.ondemand.ids[count.index]
}
