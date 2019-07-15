
variable "bastion_ip_address" {}
variable "bastion_private_ssh_key"{}
variable "master_private_ip" {
  type="list"
}
variable "infra_private_ip" {
   type="list"
}
variable "app_private_ip" {
   type="list"
}
variable "storage_private_ip" {
   type="list"
}

variable "master_hostname" {
   type = "list"
}

variable "infra_hostname" {
   type = "list"
}

variable "app_hostname" {
   type = "list"
}

variable "storage_hostname" {
   type = "list"
}

variable "domain" {

}
