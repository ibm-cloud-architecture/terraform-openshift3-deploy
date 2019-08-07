## terraform-openshift-deploy

This is meant to be used as a module, make sure your module implementation sets all the variables in its terraform.tfvars file.

```terraform
module "openshift" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-deploy.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    infra_private_ip        = "${module.infrastructure.infra_private_ip}"
    app_private_ip          = "${module.infrastructure.app_private_ip}"
    storage_private_ip      = "${module.infrastructure.storage_private_ip}"
    bastion_hostname        = "${module.infrastructure.bastion_hostname}"
    master_hostname         = "${module.infrastructure.master_hostname}"
    infra_hostname          = "${module.infrastructure.infra_hostname}"
    app_hostname            = "${module.infrastructure.app_hostname}"
    storage_hostname        = "${module.infrastructure.storage_hostname}"
    domain                  = "${var.domain}"
    ssh_user                = "${var.ssh_user}"
    cloudprovider           = "${var.cloudprovider}"
    bastion                 = "${var.bastion}"
    master                  = "${var.master}"
    infra                   = "${var.infra}"
    worker                  = "${var.worker}"
    storage                 = "${var.storage}"
    ose_version             = "${var.ose_version}"
    ose_deployment_type     = "${var.ose_deployment_type}"
    image_registry          = "${var.image_registry}"
    image_registry_username = "${var.image_registry_username == "" ? var.rhn_username : ""}"
    image_registry_password = "${var.image_registry_password == "" ? var.rhn_password : ""}"
    master_cluster_hostname = "${module.infrastructure.public_master_vip}"
    cluster_public_hostname = "${var.master_cname}-${random_id.tag.hex}.${var.domain}"
    app_cluster_subdomain   = "${var.app_cname}-${random_id.tag.hex}.${var.domain}"
    registry_volume_size    = "${var.registry_volume_size}"
    dnscerts                = "${var.dnscerts}"
    haproxy                 = "${var.haproxy}"
    pod_network_cidr        = "${var.network_cidr}"
    service_network_cidr    = "${var.service_network_cidr}"
    host_subnet_length      = "${var.host_subnet_length}"
    # admin_password          = "${random_string.password.result}"
}
```

## Module Inputs Variables

|Variable Name|Description|Default Value|Type|
|-------------|-----------|-------------|----|
|bastion_ip_address|Public IPv4 Address of Bastion Node|-|string|
|bastion_private_ssh_key|Private SSH key|-|string|
|ssh_user|SSH user.  Must have passwordless sudo access|-|string|
|master_private_ip|List of Private IPv4 Addresses of Master Nodes|-|list|
|infra_private_ip|List of Private IPv4 Private Addresses of Infra Nodes|-|list|
|app_private_ip|List of Private IPv4 Private Addresses of Worker Nodes|-|list|
|storage_private_ip|List of Private IPv4 Private Addresses of Storage Nodes|-|list|
|haproxy_public_ip|List of Public IPv4 Private Addresses of HAProxy Nodes|-|list|
|bastion_hostname|Hostname of Bastion Node|-|string|
|master_hostname|List of Hostnames of Master Nodes|-|list|
|infra_hostname|List of Hostnames of Infra Nodes|-|list|
|app_hostname|List of Hostnames of Worker Nodes|-|list|
|storage_hostname|List of Hostnames of Storage Nodes|-|list|
|haproxy_hostname|List of Hostnames of HAProxy Nodes|-|list|
|domain|Custom DNS to use for OpenShift|-|string|
|cloudprovider|Cloud Provider Identifier|-|string|
|bastion|A map variable for configuration of bastion node|See sample variables.tf|
|master|A map variable for configuration of master nodes|See sample variables.tf|
|infra|A map variable for configuration of infra nodes|See sample variables.tf|
|worker|A map variable for configuration of worker nodes|See sample variables.tf|
|storage|A map variable for configuration of storage nodes|See sample variables.tf|
|haproxy|A map variable for configuration of haproxy nodes|See sample variables.tf|
|ose_version|OpenShift version to install|v3.11|string|
|ose_deployment_type|OpenShift Deployment Type|openshift-enterprise|string|
|image_registry|Docker image registry to use|registry.redhat.io|string|
|image_registry_username|Image Registry username|-|string|
|image_registry_password|Image Registry password|-|string|
|registry_volume_size|Size of Image Registry PVC|100|number|
|master_cluster_hostname|Loadbalancer FQDN/VIP for master cluster|-|string|
|cluster_public_hostname|Loadbalancer FQDB/VIP for apps cluster|-|string|
|app_cluster_subdomain|Apps subdomain to use for deployments ex: `apps.example.com`|-|string|
|dnscerts|Control variable.  Are we using certificates?|false|bool|
|haproxy|Control variable. Are we using HAProxy Nodes?|false|bool|
|pod_network_cidr|Value for `osm_cluster_network_cidr` in inventory.cfg|10.128.0.0/14|string
|service_network_cidr|Value for `openshift_portal_net` in inventory.cfg|172.30.0.0/16|string|
|host_subnet_length|Value for `osm_host_subnet_length` in inventory.cfg|9|number|

## Module Output
This module produces no terraform output.  

----
