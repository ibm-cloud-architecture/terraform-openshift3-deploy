#!/bin/bash

exec 3>&1 4>&2 1> >(tee $0.log.$$ >&3) 2> >(tee $0.log.$$ >&4)

echo "Execute prepare_nodes.sh on $(hostname)"
yum -y update
yum install -y wget vim-enhanced net-tools bind-utils tmux git iptables-services bridge-utils docker etcd rpcbind

echo "CONFIGURING DOCKER STORAGE, DOCKER_DEVICE=${docker_block_dev}"

cat <<EOF | sudo tee /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=${docker_block_dev}
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=dockervg
EOF

# stopping docker and cleaning file system before reconfiguring it
sudo systemctl enable docker
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/*

sudo docker-storage-setup

sudo systemctl restart docker
sudo systemctl is-active docker

for config in /etc/sysconfig/network-scripts/ifcfg-e*; do
    sed -i -e '/NM_CONTROLLED=/d' $config
    echo "NM_CONTROLLED=yes" >> $config
done

systemctl enable NetworkManager
systemctl start NetworkManager

sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
setenforce 1
