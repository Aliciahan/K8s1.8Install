#!/bin/bash

kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/etcd/ssl/ca.pem \
  --embed-certs=true \
  --server=https://192.168.94.134:6443
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
kubectl config use-context kubernetes
