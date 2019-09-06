output "installed_resource" {
    value = "${join(",", list(null_resource.prerequisites.id, null_resource.deploy_cluster.id, null_resource.create_cluster_admin.id))}"
}

output "openshift_inventory" {
    value = "${data.template_file.ansible_inventory.rendered}"
}