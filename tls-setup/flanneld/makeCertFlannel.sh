#!/bin/bash

cfssl gencert -ca=../certs/ca.pem \
  -ca-key=../certs/ca-key.pem \
  -config=../config/ca-config.json \
  flanneld-csr.json | cfssljson -bare flanneld
