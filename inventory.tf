#--------------------------------#
#--------------------------------#
locals {
    gluster_storage_devices = "\"${var.storage["gluster_disk_device"]}\""
}

# ansible inventory file
data "template_file" "ansible_inventory" {
  template = <<EOF
[OSEv3:children]
masters
etcd
nodes
glusterfs
${var.haproxy["nodes"] != "0" ? "lb" : ""}

[OSEv3:vars]
ansible_ssh_user=${var.ssh_user}
${var.ssh_user == "root" ? "" : "ansible_become=true"}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
openshift_deployment_type=${var.ose_deployment_type}
openshift_release=v${var.openshift_version}
containerized=true
openshift_use_crio=false
os_sdn_network_plugin_name=redhat/openshift-ovs-networkpolicy
osm_cluster_network_cidr=${var.pod_network_cidr}
openshift_portal_net=${var.service_network_cidr}
osm_host_subnet_length=${var.host_subnet_length}
openshift_master_api_port=443
openshift_master_console_port=443
os_firewall_use_firewalld=true
# disable docker_storage check on non-rhel since the python-docker library cannot connect to docker for some reason
openshift_disable_check=docker_storage,docker_image_availability,package_version
oreg_auth_user=${var.image_registry_username}
oreg_auth_password=${var.image_registry_password}
oreg_test_login=false
openshift_certificate_expiry_fail_on_warn=false
openshift_docker_options='--selinux-enabled --insecure-registry ${var.service_network_cidr} --log-driver=json-file --log-opt max-size=1M --log-opt max-file=3'
# master console
openshift_master_cluster_method=native
openshift_master_cluster_hostname=${var.master_cluster_hostname}
openshift_master_cluster_public_hostname=${var.cluster_public_hostname}
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={'admin': '$apr1$qSzqkDd8$fU.yI4bV8KmXD9kreFSL//'}
# if we're using oidc, and it uses a trusted cert, we can use the system truststore
openshift_master_openid_ca_file=/etc/ssl/certs/ca-bundle.crt
${var.dnscerts ? "openshift_master_named_certificates=[{'certfile': '~/master.crt', 'keyfile': '~/master.key', 'names': ['${var.cluster_public_hostname}']}]" : "" }
${var.dnscerts ? "openshift_master_overwrite_named_certificates=true" : ""}
# router
openshift_master_default_subdomain=${var.app_cluster_subdomain}
${var.dnscerts ? "openshift_hosted_router_certificate={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}" : ""}
# cluster console
openshift_console_install=true
${var.dnscerts ? "openshift_console_cert=~/router.crt" : ""}
${var.dnscerts ? "openshift_console_key=~/router.key" : ""}
# registry certs
openshift_hosted_registry_routehost=registry.${var.app_cluster_subdomain}
${var.dnscerts ? "openshift_hosted_registry_routetermination=reencrypt" : ""}
${var.dnscerts ? "openshift_hosted_registry_routecertificates={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}" : "" }
openshift_hosted_registry_storage_kind=glusterfs
openshift_hosted_registry_storage_volume_size=${var.registry_volume_size}Gi
openshift_storage_glusterfs_block_deploy=true
openshift_storage_glusterfs_block_storageclass=true
openshift_storage_glusterfs_storageclass=true
openshift_storage_glusterfs_storageclass_default=true
# gluster images
openshift_storage_glusterfs_image=${var.image_registry}/rhgs3/rhgs-server-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_block_image=${var.image_registry}/rhgs3/rhgs-gluster-block-prov-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_s3_image=${var.image_registry}/rhgs3/rhgs-s3-server-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_heketi_image=${var.image_registry}/rhgs3/rhgs-volmanager-rhel7:v${var.openshift_version}


# monitoring
openshift_cluster_monitoring_operator_install=true
openshift_cluster_monitoring_operator_prometheus_storage_enabled=true
openshift_cluster_monitoring_operator_prometheus_storage_class_name=glusterfs-storage-block
openshift_cluster_monitoring_operator_alertmanager_storage_enabled=true
openshift_cluster_monitoring_operator_alertmanager_storage_class_name=glusterfs-storage-block
openshift_cluster_monitoring_operator_node_selector={"node-role.kubernetes.io/infra":"true"}

# metrics
openshift_metrics_install_metrics=true
openshift_metrics_cassandra_storage_type=dynamic
openshift_metrics_cassandra_pvc_storage_class_name=glusterfs-storage-block
openshift_metrics_hawkular_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_cassandra_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_heapster_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_storage_volume_size=20Gi
# logging
openshift_logging_install_logging=true
openshift_logging_es_pvc_dynamic=true
openshift_logging_es_pvc_storage_class_name=glusterfs-storage-block
openshift_logging_es_pvc_size=20Gi
openshift_logging_es_ops_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_es_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_kibana_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_curator_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_es_cluster_size=${var.infra["nodes"]}
openshift_logging_es_memory_limit=8Gi
openshift_logging_es_ops_memory_limit=8Gi


[masters]
${join("\n", formatlist("%v.%v",var.master_hostname, var.domain))}

[etcd]
${join("\n", formatlist("%v.%v etcd_ip=%v",var.master_hostname, var.domain, var.master_private_ip))}

${var.storage["nodes"] == "0" ? "" : "[glusterfs]"}
${var.storage["nodes"] == "0" ? "" : "${join("\n", formatlist("%v.%v glusterfs_devices='[ %v ]' openshift_node_group_name='node-config-compute'", var.storage_hostname, var.domain, local.gluster_storage_devices))}"}

[nodes]
${join("\n", formatlist("%v.%v openshift_node_group_name=\"node-config-master\"", var.master_hostname, var.domain))}
${join("\n", formatlist("%v.%v openshift_node_group_name=\"node-config-infra\"", var.infra_hostname, var.domain))}
${join("\n", formatlist("%v.%v openshift_node_group_name=\"node-config-compute\"", var.app_hostname, var.domain))}
${var.storage["nodes"] == "0" ? "" : "${join("\n", formatlist("%v.%v openshift_schedulable=True openshift_node_group_name=\"node-config-compute\"", var.storage_hostname, var.domain))}"}

${var.haproxy["nodes"] != "0" ? "[lb]" : ""}
${var.haproxy["nodes"] != "0" ? "${join("\n", formatlist("%v.%v", var.haproxy_hostname, var.domain))}" : ""}
EOF
}

data "template_file" "ansible_inventory_azure" {
    template = <<EOF
[OSEv3:children]
masters
etcd
nodes

[OSEv3:vars]
ansible_ssh_user=${var.ssh_user}
${var.ssh_user == "root" ? "" : "ansible_become=true"}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
openshift_deployment_type=${var.ose_deployment_type}
openshift_release=v${var.openshift_version}
containerized=true
openshift_use_crio=false
os_sdn_network_plugin_name=redhat/openshift-ovs-networkpolicy
osm_cluster_network_cidr=${var.pod_network_cidr}
openshift_portal_net=${var.service_network_cidr}
osm_host_subnet_length=${var.host_subnet_length}
openshift_master_api_port=443
openshift_master_console_port=443
os_firewall_use_firewalld=true
# disable docker_storage check on non-rhel since the python-docker library cannot connect to docker for some reason
openshift_disable_check=docker_storage,docker_image_availability,package_version
oreg_auth_user=${var.image_registry_username}
oreg_auth_password=${var.image_registry_password}
oreg_test_login=false
openshift_certificate_expiry_fail_on_warn=false
openshift_docker_options='--selinux-enabled --insecure-registry ${var.service_network_cidr} --log-driver=json-file --log-opt max-size=1M --log-opt max-file=3'
# master console
openshift_master_cluster_method=native
openshift_master_cluster_hostname=${var.master_cluster_hostname}
openshift_master_cluster_public_hostname=${var.cluster_public_hostname}
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={'admin': '$apr1$qSzqkDd8$fU.yI4bV8KmXD9kreFSL//'}
# if we're using oidc, and it uses a trusted cert, we can use the system truststore
openshift_master_openid_ca_file=/etc/ssl/certs/ca-bundle.crt
${var.dnscerts ? "openshift_master_named_certificates=[{'certfile': '~/master.crt', 'keyfile': '~/master.key', 'names': ['${var.cluster_public_hostname}']}]" : "" }
${var.dnscerts ? "openshift_master_overwrite_named_certificates=true" : ""}
# router
openshift_master_default_subdomain=${var.app_cluster_subdomain}
${var.dnscerts ? "openshift_hosted_router_certificate={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}" : ""}
# cluster console
openshift_console_install=true
${var.dnscerts ? "openshift_console_cert=~/router.crt" : ""}
${var.dnscerts ? "openshift_console_key=~/router.key" : ""}
# registry certs
openshift_hosted_registry_routehost=registry.${var.app_cluster_subdomain}
${var.dnscerts ? "openshift_hosted_registry_routetermination=reencrypt" : ""}
${var.dnscerts ? "openshift_hosted_registry_routecertificates={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}" : "" }

openshift_cloudprovider_kind=azure
openshift_cloudprovider_azure_client_id=${var.azure_client_id}
openshift_cloudprovider_azure_client_secret=${var.azure_client_secret}
openshift_cloudprovider_azure_tenant_id=${var.azure_tenant_id}
openshift_cloudprovider_azure_subscription_id=${var.azure_subscription_id}
openshift_cloudprovider_azure_resource_group=${var.azure_resource_group}
openshift_cloudprovider_azure_location=${var.azure_location}

# Storage Class change to use managed storage
openshift_storageclass_parameters={'kind': 'managed', 'storageaccounttype': 'Premium_LRS'}

# Azure Registry Configuration
openshift_hosted_registry_replicas=1
openshift_hosted_registry_storage_kind=object
openshift_hosted_registry_storage_azure_blob_accountkey=${var.azure_storage_accountkey}
openshift_hosted_registry_storage_provider=azure_blob
openshift_hosted_registry_storage_azure_blob_accountname=${var.azure_storage_account}
openshift_hosted_registry_storage_azure_blob_container=registry
openshift_hosted_registry_storage_azure_blob_realm=core.windows.net

# monitoring
openshift_cluster_monitoring_operator_install=true
openshift_cluster_monitoring_operator_prometheus_storage_enabled=true
openshift_cluster_monitoring_operator_alertmanager_storage_enabled=true
openshift_cluster_monitoring_operator_node_selector={"node-role.kubernetes.io/infra":"true"}

# metrics
openshift_metrics_install_metrics=true
openshift_metrics_cassandra_storage_type=dynamic
openshift_metrics_hawkular_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_cassandra_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_heapster_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_storage_volume_size=20Gi

# logging
openshift_logging_install_logging=true
openshift_logging_es_pvc_dynamic=true
openshift_logging_es_pvc_size=20Gi
openshift_logging_es_ops_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_es_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_kibana_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_curator_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_es_cluster_size=${var.infra["nodes"]}
openshift_logging_es_memory_limit=8Gi
openshift_logging_es_ops_memory_limit=8Gi


[masters]
${join("\n", formatlist("%v",var.master_hostname))}

[etcd]
${join("\n", formatlist("%v etcd_ip=%v",var.master_hostname, var.master_private_ip))}

[nodes]
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-master\"", var.master_hostname))}
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-infra\"", var.infra_hostname))}
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-compute\"", var.app_hostname))}
EOF
}


#--------------------------------#
#--------------------------------#

resource "null_resource" "copy_ansible_inventory" {
    count = "${var.storageprovider == "glusterfs" ? 1 : 0}"
    triggers = {
        inventory = "${data.template_file.ansible_inventory.rendered}"
    }

    connection {
        type = "ssh"
        host = "${var.bastion_ip_address}"
        user = "${var.ssh_user}"
        private_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
        when = "create"
        content     = "${data.template_file.ansible_inventory.rendered}"
        destination = "~/inventory.cfg"
    }
}

resource "null_resource" "copy_ansible_inventory_azure" {
    count = "${var.storageprovider == "azure" ? 1 : 0}"
    triggers = {
        inventory = "${data.template_file.ansible_inventory_azure.rendered}"
    }

    connection {
        type = "ssh"
        host = "${var.bastion_ip_address}"
        user = "${var.ssh_user}"
        private_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
        when = "create"
        content     = "${data.template_file.ansible_inventory_azure.rendered}"
        destination = "~/inventory.cfg"
    }
}
