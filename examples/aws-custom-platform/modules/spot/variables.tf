variable "globals" {
  description = "Map of global variables."
}

variable "image_id" {
  type        = string
  description = "Amazon Machine Image ID."
}

variable "instance_type" {
  type        = string
  description = "Local instance type."
}

variable "node_count" {
  type        = number
  description = "Number of nodes/machines."
}

variable "tags" {
  description = "Map of local tags."
}

variable "user_data" {
  description = "User data script to be passed to cloud-init."
}

variable "volume_size" {
  type        = string
  description = "Size of root volume."
}
