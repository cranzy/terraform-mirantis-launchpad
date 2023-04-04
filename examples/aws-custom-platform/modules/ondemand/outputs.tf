output "node_ids" {
  value = local.node_ids
}

output "instances" {
  value = data.aws_instance.instance
}
