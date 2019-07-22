#!/bin/sh

echo "Execute prepare_nodes.sh on $(hostname)"
rm -fr /var/cache/yum/*
yum clean all
yum -y update
yum install -y wget vim-enhanced net-tools bind-utils tmux git iptables-services bridge-utils docker etcd rpcbind

if [ -z `grep docker /etc/group`]; then
  groupadd docker
fi

echo "CONFIGURING DOCKER STORAGE"

cat <<EOF | sudo tee /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=$(test -e /dev/xvdc && echo /dev/xvdc || echo /dev/sdc)
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=dockervg
EOF

sudo docker-storage-setup

sudo systemctl enable docker
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/*
sudo systemctl restart docker
sudo systemctl is-active docker

for config in /etc/sysconfig/network-scripts/ifcfg-eth*; do
    sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=yes/' $config
done

systemctl enable NetworkManager
systemctl start NetworkManager

sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
setenforce 1
