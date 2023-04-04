variable "cluster_name" {}

variable "master_count" {}

variable "ssh_key" {}

variable "master_image_name" {}

variable "master_flavor" {}

variable "master_volume_size" {
  default = 50
}

variable "external_network_name" {}

variable "internal_network_name" {}

variable "internal_subnet_id" {}

variable "base_sec_group_id" {}
