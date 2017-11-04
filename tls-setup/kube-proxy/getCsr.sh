#!/bin/bash

cfssl gencert -ca=../certs/ca.pem \
  -ca-key=../certs/ca-key.pem \
  -config=../config/ca-config.json \
  kube-proxy-csr.json | cfssljson -bare kube-proxy &&\
cp ./kube-proxy* /etc/kubernetes/ssl/
