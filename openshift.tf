locals {
  all_node_ips = "${concat(var.master_private_ip, var.infra_private_ip, var.app_private_ip, var.storage_private_ip)}"
  all_node_ips_incl_bastion = "${concat(list(var.bastion_ip_address), var.master_private_ip, var.infra_private_ip, var.app_private_ip, var.storage_private_ip)}"
}

resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = "${join(",", var.dependson)}"
  }
}

#################################################
# Prepare to install Openshift
#################################################
data "template_file" "prepare_node_common_sh" {
  template = "${file("${path.module}/templates/prepare_node_common.sh.tpl")}"

  vars = {
    openshift_version = "${var.openshift_version}"
    ansible_version = "${var.ansible_version}"
  }
}

data "template_file" "prepare_node_sh" {
  template = "${file("${path.module}/templates/prepare_node.sh.tpl")}"

  vars = {
    docker_block_dev = "${var.master["docker_disk_device"]}"
  }
}


resource "null_resource" "pre_install_node_common" {
  count = "${length(local.all_node_ips_incl_bastion)}"

  depends_on = [
    "null_resource.dependency"
  ]

  triggers = {
    node_list = "${join(",", local.all_node_ips_incl_bastion)}"
    prepare_node_common_sh = "${data.template_file.prepare_node_common_sh.rendered}"
  }

  connection {
    type = "ssh"
    host = "${element(local.all_node_ips_incl_bastion, count.index)}"
    user = "${var.ssh_user}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "file" {
    content = "${data.template_file.prepare_node_common_sh.rendered}"
    destination = "/tmp/prepare_node_common.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/prepare_node_common.sh",
        "sudo /tmp/prepare_node_common.sh"
    ]
  }
}

resource "null_resource" "pre_install_cluster" {
  count = "${length(local.all_node_ips)}"

  depends_on = [
    "null_resource.dependency",
    "null_resource.pre_install_node_common"
  ]

  triggers = {
    prepare_node_sh = "${data.template_file.prepare_node_sh.rendered}"
  }

  connection {
    type = "ssh"
    host = "${element(local.all_node_ips, count.index)}"
    user = "${var.ssh_user}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"

  }

  provisioner "file" {
    content      = "${data.template_file.prepare_node_sh.rendered}"
    destination = "/tmp/prepare_node.sh"
  }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/prepare_node.sh",
        "chmod 600 ~/.ssh/id_rsa",
        "sudo /tmp/prepare_node.sh",
      ]
    }
}

resource "null_resource" "pre_install_cluster_bastion" {
  depends_on = [
    "null_resource.dependency",
    "null_resource.pre_install_node_common",
    "null_resource.copy_ansible_inventory"
  ]

  connection {
      type = "ssh"
      host = "${var.bastion_ip_address}"
      user = "${var.ssh_user}"
      private_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/prepare_bastion.sh"
    destination = "/tmp/prepare_bastion.sh"
  }

  provisioner "remote-exec" {
      inline = [
          "chmod +x /tmp/prepare_bastion.sh",
          "chmod 600 ~/.ssh/id_rsa",
          "sudo /tmp/prepare_bastion.sh",
      ]
  }
}

#################################################
# Install Openshift
#################################################
resource "null_resource" "prerequisites" {
  depends_on = [
    "null_resource.pre_install_cluster_bastion",
    "null_resource.pre_install_cluster",
  ]

  triggers = {
    inventory = "${data.template_file.ansible_inventory.rendered}"
  }

  connection {
    type     = "ssh"
    host = "${var.bastion_ip_address}"
    user = "${var.ssh_user}"
    private_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
        "ansible-playbook -i /tmp/inventory.cfg /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml",
    ]
  }
}

resource "null_resource" "deploy_cluster" {
  depends_on = [
     "null_resource.prerequisites"
  ]

  triggers = {
    inventory = "${data.template_file.ansible_inventory.rendered}"
  }

  connection {
    type     = "ssh"
    host = "${var.bastion_ip_address}"
    user = "${var.ssh_user}"
    private_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
        "ansible-playbook -i /tmp/inventory.cfg /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml",
    ]
  }
}

#################################################
# Perform post-install configurations for Openshift
#################################################
resource "null_resource" "post_install_cluster" {
  count = "${length(local.all_node_ips)}"

  connection {
      type = "ssh"
      host = "${element(local.all_node_ips, count.index)}"
      user = "${var.ssh_user}"
      private_key = "${file(var.bastion_private_ssh_key)}"
      bastion_host = "${var.bastion_ip_address}"
      bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/post_install_node.sh"
    destination = "/tmp/post_install_node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/post_install_node.sh",
      "/tmp/post_install_node.sh"
    ]
  }

  depends_on    = ["null_resource.deploy_cluster"]
}
