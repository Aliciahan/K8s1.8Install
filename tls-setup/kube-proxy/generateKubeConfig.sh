#!/bin/bash

kubectl config set-cluster kubernetes \
--certificate-authority=/etc/etcd/ssl/ca.pem \
--embed-certs=true \
--server=https://192.168.94.134:6443 \
--kubeconfig=kube-proxy.kubeconfig 
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
--client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
--client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
--embed-certs=true \
--kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
--cluster=kubernetes \
--user=kube-proxy \
--kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
cp kube-proxy.kubeconfig /etc/kubernetes/

