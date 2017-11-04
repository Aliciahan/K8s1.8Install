#!/bin/bash
yum erase docker-1.12.6-61.git85d7426.el7.centos.x86_64
yum erase docker-common-2:1.12.6-61.git85d7426.el7.centos.x86_64
wget -qO- https://get.docker.com/ | sh
systemctl daemon-reload
systemctl restart docker
