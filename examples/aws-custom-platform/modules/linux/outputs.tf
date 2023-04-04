output "node_ids" {
  # value = module.spot.node_ids
  value = local.node_ids
}

output "instances" {
  value = local.instances
}

output "user" {
  value = module.ami.user
}
