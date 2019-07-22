#################################################
# Prepare to install Openshift
#################################################
resource "null_resource" "pre_install_cluster_bastion" {
    connection {
        type = "ssh"
        user = "root"
        host = "${var.bastion_ip_address}"
        private_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
      source      = "${path.root}/inventory_repo/"
      destination = "~/"
    }

    provisioner "file" {
      source      = "${path.module}/scripts"
      destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts/*",
            "cat ~/hosts >> /etc/hosts",
            "chmod 600 ~/.ssh/id_rsa",
            "/tmp/scripts/prepare_bastion.sh",
        ]
    }

}

resource "null_resource" "pre_install_cluster_master" {
    count = "${var.master_count}"
    connection {
        type = "ssh"
        user = "root"
        host = "${element(var.master_private_ip, count.index)}"
        private_key = "${file(var.bastion_private_ssh_key)}"
        bastion_host = "${var.bastion_ip_address}"
        bastion_host_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
      source      = "${path.root}/inventory_repo/"
      destination = "~/"
    }

    provisioner "file" {
      source      = "${path.module}/scripts"
      destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts/*",
            "cat ~/hosts >> /etc/hosts",
            "/tmp/scripts/prepare_node.sh"
        ]
    }

}

resource "null_resource" "pre_install_cluster_infra" {
    count = "${var.infra_count}"
    connection {
        type = "ssh"
        user = "root"
        host = "${element(var.infra_private_ip, count.index)}"
        private_key = "${file(var.bastion_private_ssh_key)}"
        bastion_host = "${var.bastion_ip_address}"
        bastion_host_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
      source      = "${path.root}/inventory_repo/"
      destination = "~/"
    }

    provisioner "file" {
      source      = "${path.module}/scripts"
      destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts/*",
            "cat ~/hosts >> /etc/hosts",
            "/tmp/scripts/prepare_node.sh"
        ]
    }
}

resource "null_resource" "pre_install_cluster_app" {
    count = "${var.app_count}"
    connection {
        type = "ssh"
        user = "root"
        host = "${element(var.app_private_ip, count.index)}"
        private_key = "${file(var.bastion_private_ssh_key)}"
        bastion_host = "${var.bastion_ip_address}"
        bastion_host_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
      source      = "${path.root}/inventory_repo/"
      destination = "~/"
    }

    provisioner "file" {
      source      = "${path.module}/scripts"
      destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts/*",
            "cat ~/hosts >> /etc/hosts",
            "/tmp/scripts/prepare_node.sh"
        ]
    }
}


resource "null_resource" "pre_install_cluster_storage" {
    count = "${var.storage_count}"
    connection {
        type = "ssh"
        user = "root"
        host = "${element(var.storage_private_ip, count.index)}"
        private_key = "${file(var.bastion_private_ssh_key)}"
        bastion_host = "${var.bastion_ip_address}"
        bastion_host_key = "${file(var.bastion_private_ssh_key)}"
    }

    provisioner "file" {
      source      = "${path.root}/inventory_repo/"
      destination = "~/"
    }

    provisioner "file" {
      source      = "${path.module}/scripts"
      destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts/*",
            "cat ~/hosts >> /etc/hosts",
            "/tmp/scripts/prepare_node.sh"
        ]
    }
}

#################################################
# Install Openshift
#################################################
resource "null_resource" "deploy_cluster" {
 depends_on = [
     "null_resource.pre_install_cluster_bastion",
     "null_resource.pre_install_cluster_master",
     "null_resource.pre_install_cluster_infra",
     "null_resource.pre_install_cluster_app",
     "null_resource.pre_install_cluster_storage",
 ]

  connection {
    type     = "ssh"
    user     = "root"
    host = "${var.bastion_ip_address}"
    private_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "file" {
    source      = "${path.root}/inventory_repo/"
    destination = "~/"
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x ~/*",
        "ansible-playbook -i ~/inventory.cfg /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml",
        "ansible-playbook -i ~/inventory.cfg /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml",
    ]
  }
}

#################################################
# Perform post-install configurations for Openshift
#################################################
resource "null_resource" "post_install_cluster_master" {
  count = "${var.master_count}"
  connection {
    type     = "ssh"
    user     = "root"
    host = "${element(var.master_private_ip, count.index)}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "/tmp/scripts/post_install_node.sh",
    ]
  }
  depends_on    = ["null_resource.deploy_cluster"]
}

resource "null_resource" "post_install_cluster_infra" {
  count = "${var.infra_count}"
  connection {
    type     = "ssh"
    user     = "root"
    host = "${element(var.infra_private_ip, count.index)}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "/tmp/scripts/post_install_node.sh",
    ]
  }
  depends_on    = ["null_resource.deploy_cluster"]
}

resource "null_resource" "post_install_cluster_app" {
  count = "${var.app_count}"
  connection {
    type     = "ssh"
    user     = "root"
    host = "${element(var.app_private_ip, count.index)}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "/tmp/scripts/post_install_node.sh",
    ]
  }
  depends_on    = ["null_resource.deploy_cluster"]
}

resource "null_resource" "post_install_cluster_storage" {
  count = "${var.storage_count}"
  connection {
    type     = "ssh"
    user     = "root"
    host = "${element(var.storage_private_ip, count.index)}"
    private_key = "${file(var.bastion_private_ssh_key)}"
    bastion_host = "${var.bastion_ip_address}"
    bastion_host_key = "${file(var.bastion_private_ssh_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "/tmp/scripts/post_install_node.sh",
    ]
  }
  depends_on    = ["null_resource.deploy_cluster"]
}
