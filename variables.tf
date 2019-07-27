
variable "bastion_ip_address" {}
variable "bastion_private_ssh_key"{}

variable "master_private_ip"  { type = "list" }
variable "infra_private_ip"   { type = "list" }
variable "app_private_ip"     { type = "list" }
variable "storage_private_ip" { type = "list" }

variable "master_hostname"    { type = "list" }
variable "infra_hostname"     { type = "list" }
variable "app_hostname"       { type = "list" }
variable "storage_hostname"   { type = "list" }

variable "domain" {}

variable "openshift_identity_provider" {
    # admin/admin
    default = "openshift_master_htpasswd_users={'admin': '$apr1$qSzqkDd8$fU.yI4bV8KmXD9kreFSL//'}"
}

variable "registry_volume_size" {
    default = "100"
}

variable "dnscerts" {
    default = false
}

variable "ssh_username" {
    default = "root"
}

variable "cloudprovider" {
    default = "ibm"
}

variable "bastion" { type = "map" }
variable "master"  { type = "map" }
variable "infra"   { type = "map" }
variable "worker"  { type = "map" }
variable "storage" { type = "map" }
