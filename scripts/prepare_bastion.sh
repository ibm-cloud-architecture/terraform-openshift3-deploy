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
    openshift-ansible \
    atomic-openshift-utils \
    atomic-openshift-excluder \
    atomic-openshift-docker-excluder

atomic-openshift-excluder unexclude

for config in /etc/sysconfig/network-scripts/ifcfg-e*; do
    sed -i -e '/NM_CONTROLLED=/d' $config
    echo "NM_CONTROLLED=yes" >> $config
done

systemctl enable NetworkManager
systemctl start NetworkManager
