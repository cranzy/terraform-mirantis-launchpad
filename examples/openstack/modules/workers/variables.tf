variable "cluster_name" {}

variable "worker_count" {}

variable "ssh_key" {}

variable "worker_image_name" {}

variable "worker_flavor" {}

variable "worker_volume_size" {
  default = 50
}

variable "external_network_name" {}

variable "internal_network_name" {}

variable "internal_subnet_id" {}

variable "base_sec_group_id" {}
