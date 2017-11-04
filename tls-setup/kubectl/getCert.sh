#!/bin/bash

cfssl gencert -ca=/etc/etcd/ssl/ca.pem \
  -ca-key=/etc/etcd/ssl/ca-key.pem \
  -config=../config/ca-config.json \
  admin-csr.json | cfssljson -bare admin

EXCODE=$?
if [ "$EXCODE" == "0" ]; then
    if [[ -d /etc/kubernetes/ssl ]]; then
        cp ./admin* /etc/kubernetes/ssl/
    else
        mkdir -p /etc/kubernetes/ssl && \
        cp ./admin* /etc/kubernetes/ssl/
    fi
fi


