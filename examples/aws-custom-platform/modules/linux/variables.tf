variable "node_count" {
  type        = number
  default     = 3
  description = "Number of nodes/machines."
}

variable "instance_type" {
  type        = string
  default     = "m5.large"
  description = "AWS instance type of the nodes/machines."
}

variable "volume_size" {
  type        = number
  default     = 100
  description = "Size in GB of the root volume of the nodes/machines."
}

variable "role" {
  type        = string
  description = "The node's role in the cluster, ie, manager/worker/msr/windows."
}

variable "life_cycle" {
  type        = string
  default     = "ondemand"
  description = "Deploy instances as either 'spot' or 'ondemand'"
}

variable "globals" {
  description = "Map of global variables."
}
