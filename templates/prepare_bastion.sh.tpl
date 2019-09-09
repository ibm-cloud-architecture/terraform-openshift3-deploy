#!/bin/bash

exec 3>&1 4>&2 1> >(tee $0.log.$$ >&3) 2> >(tee $0.log.$$ >&4)

echo "Execute prepare_bastion.sh on $(hostname)"

rm -fr /var/cache/yum/*
yum clean all
yum update -y
yum install -y wget \
    git \
    net-tools \
    bind-utils \
    yum-utils \
    iptables-services \
    bridge-utils \
    bash-completion \
    kexec-tools \
    sos \
    psacct \
    vim \
    tmux \
    docker \
    openshift-ansible \
    atomic-openshift-utils \
    atomic-openshift-excluder \
    atomic-openshift-docker-excluder

echo "CONFIGURING DOCKER STORAGE, DOCKER_DEVICE=${docker_block_dev}"

cat <<EOF | sudo tee /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=${docker_block_dev}
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

atomic-openshift-excluder unexclude



for config in /etc/sysconfig/network-scripts/ifcfg-e*; do
    sed -i -e '/NM_CONTROLLED=/d' $config
    echo "NM_CONTROLLED=yes" >> $config
done

systemctl enable NetworkManager
systemctl start NetworkManager
