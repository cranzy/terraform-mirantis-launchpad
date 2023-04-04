output "lb_dns_name" {
  value = lower(aws_lb.lb.dns_name)
}
