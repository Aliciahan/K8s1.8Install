#!/bin/bash

cfssl gencert -ca=/etc/etcd/ssl/ca.pem \
  -ca-key=../certs/ca-key.pem \
  -config=../config/ca-config.json \
  kubernetes-csr.json | cfssljson -bare kubernetes &&\
mkdir -p /etc/kubernetes/ssl &&\
cp kubernetes* /etc/kubernetes/ssl
