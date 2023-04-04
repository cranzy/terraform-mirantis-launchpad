variable "cluster_name" {}

variable "external_network_id" {}

variable "cidr" {
  default = "10.0.100.0/24"
}

variable "dns_ips" {
  type    = list(string)
}
