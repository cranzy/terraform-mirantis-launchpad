variable "globals" {
  description = "Map of global variables."
}

variable "node_count" {
  type        = number
  default     = 0
  description = "Number of Windows nodes."
}

variable "role" {
  type        = string
  description = "The node's role in the cluster, ie, manager/worker/msr."
}

variable "life_cycle" {
  type        = string
  default     = "ondemand"
  description = "Deploy instances as either 'spot' or 'ondemand'"
}

variable "instance_type" {
  type        = string
  default     = "m5.large"
  description = "AWS instance type of the nodes/machines."
}

variable "volume_size" {
  default = 100
}

variable "win_admin_password" {
  type        = string
  description = "Windows administrator password."
}
