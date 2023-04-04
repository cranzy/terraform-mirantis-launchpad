# Bootstrapping MKE cluster on VMware vSphere

This directory provides an example flow with Mirantis Launchpad tool together with Terraform using [VMware vSphere](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs) as the cloud provider.


## Prerequisites

* You need VMware vSphere credentials for API operations
* Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install)

## Steps

1. Create a terraform.tfvars file with the necessary details. You can use the provided terraform.tfvars.example as a baseline.
2. `terraform init`
3. `terraform apply`
4. `terraform output mke_cluster | launchpad apply --config -`
