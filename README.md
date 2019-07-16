## terraform-openshift-deploy

This is meant to be used as a module, make sure your module implementation sets all the variables in its terraform.tfvars file.

It creates a folder called `inventory_repo` and places a `hosts` and `inventory.cfg` file to be used for OpenShift installation



```terraform
module "openshift" {
    source                = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-deploy.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    infra_private_ip        = "${module.infrastructure.infra_private_ip}"
    app_private_ip          = "${module.infrastructure.app_private_ip}"
    storage_private_ip      = "${module.infrastructure.storage_private_ip}"
    master_hostname         = "${module.infrastructure.master_hostname}"
    infra_hostname          = "${module.infrastructure.infra_hostname}"
    app_hostname            = "${module.infrastructure.app_hostname}"
    storage_hostname        = "${module.infrastructure.storage_hostname}"
    domain                  = "${var.domain}"
}
```

## Module Inputs Variables

|Variable Name|Description|Default Value|Type|
|-------------|-----------|-------------|----|
|bastion_ip_address|Public IPv4 Address for Bastion Server|-|string|
|bastion_private_ssh_key|SSH Key for Bastion Server|-|string|
|master_private_ip|Private IPv4 Address of Master Nodes|-|list|
|infra_private_ip|Private IPv4 Address of Infra Nodes|-|list|
|app_private_ip|Private IPv4 Address of App Nodes|-|list|
|storage_private_ip|Private IPv4 Address of Storage Nodes|-|list|
|master_hostname|Hostnames of Master Nodes|-|list|
|infra_hostname|Hostnames of Infra Nodes|-|list|
|app_hostname|Hostnames of App Nodes|-|list|
|storage_hostname|Hostnames of Storage Nodes|-|list|
|domain|Custom domain for OpenShift|-|string|

## Module Output
This module produces no terraform output.  

----
