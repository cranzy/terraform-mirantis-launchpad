resource "aws_efs_file_system" "cluster" {
  encrypted = "true"
  tags      = var.globals.tags
}

resource "aws_efs_mount_target" "az" {
  file_system_id  = aws_efs_file_system.cluster.id
  subnet_id       = var.globals.subnet_id
  security_groups = [var.globals.security_group_id]
}
