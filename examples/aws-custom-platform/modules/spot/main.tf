###
# Platform-agnostic spot module
###

locals {
  node_ids = var.node_count == 0 ? [] : data.aws_instances.spot.ids
}

resource "aws_spot_fleet_request" "node" {
  iam_fleet_role                      = var.globals.iam_fleet_role
  target_capacity                     = var.node_count
  valid_until                         = var.globals.expire
  wait_for_fulfillment                = true
  terminate_instances_with_expiration = true
  tags                                = var.tags
  launch_specification {
    ami                      = var.image_id
    instance_type            = var.instance_type
    key_name                 = var.globals.ssh_key
    subnet_id                = var.globals.subnet_id
    iam_instance_profile_arn = var.globals.instance_profile.arn
    vpc_security_group_ids   = [var.globals.security_group_id]
    tags                     = var.tags
    user_data                = var.user_data
    root_block_device {
      volume_type = "gp3"
      volume_size = var.volume_size
    }
  }
}

data "aws_instances" "spot" {
  # we use this to collect the instance IDs/IPs from the spot fleet request
  filter {
    name   = "tag:aws:ec2spot:fleet-request-id"
    values = [aws_spot_fleet_request.node.id]
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [aws_spot_fleet_request.node]
}

data "aws_instance" "instance" {
  count       = var.node_count
  instance_id = data.aws_instances.spot.ids[count.index]
}
