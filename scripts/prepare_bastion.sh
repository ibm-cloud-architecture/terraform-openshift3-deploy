#!/bin/sh

echo "Execute prepare_bastion.sh on $(hostname)"

rm -fr /var/cache/yum/*
yum clean all
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum install -y vim
yum install -y tmux
yum update -y
yum install -y openshift-ansible
yum install -y atomic-openshift-utils
yum install -y atomic-openshift-excluder atomic-openshift-docker-excluder

atomic-openshift-excluder unexclude

for config in /etc/sysconfig/network-scripts/ifcfg-eth*; do
    sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=yes/' $config
done

systemctl enable NetworkManager
systemctl start NetworkManager
