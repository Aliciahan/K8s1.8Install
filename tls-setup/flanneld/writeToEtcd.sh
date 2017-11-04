#!/bin/bash

export ETCDCTL_API=2
ETCD_ENDPOINTS=https://192.168.94.134:2379,https://192.168.94.136:2379
FLANNEL_ETCD_PREFIX="/kubernetes/network"
CLUSTER_CIDR="172.30.0.0/16"

etcdctl --endpoints=$ETCD_ENDPOINTS \
    --ca-file=/etc/etcd/ssl/ca.pem \
    --cert-file=/etc/flanneld/ssl/flanneld.pem \
    --key-file=/etc/flanneld/ssl/flanneld-key.pem \
    set ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'

export ETCDCTL_API=3
