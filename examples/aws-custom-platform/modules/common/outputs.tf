output "security_group_id" {
  value = aws_security_group.common.id
}

output "instance_profile" {
  value = aws_iam_instance_profile.profile
}
