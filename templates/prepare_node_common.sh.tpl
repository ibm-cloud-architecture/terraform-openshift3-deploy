#!/bin/bash

exec 3>&1 4>&2 1> >(tee $0.log.$$ >&3) 2> >(tee $0.log.$$ >&4)

echo "Execute prepare_node_common.sh on $(hostname)"
rm -fr /var/cache/yum/*
yum clean all

subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms"  \
    --enable="rhel-7-server-extras-rpms"  \
    --enable="rhel-7-server-ose-${openshift_version}-rpms" \
    --enable="rhel-7-server-ansible-${ansible_version}-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rh-gluster-3-client-for-rhel-7-server-rpms"

for config in /etc/sysconfig/network-scripts/ifcfg-e*; do
    sed -i -e '/NM_CONTROLLED=/d' $config
    echo "NM_CONTROLLED=yes" >> $config
done

systemctl enable NetworkManager
systemctl start NetworkManager
