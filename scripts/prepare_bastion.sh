#!/bin/bash
# Install the prerequisite required by the bastion machine

yum install -y atomic-openshift-utils

yum install -y atomic-openshift-excluder atomic-openshift-docker-excluder

atomic-openshift-excluder unexclude

sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=yes/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i -e 's/NM_CONTROLLED=.*/NM_CONTROLLED=yes/' /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl enable NetworkManager
systemctl start NetworkManager
