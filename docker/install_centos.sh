#!/bin/bash

DOCKER_PATH='/usr/bin/docker'

if [ -s "${DOCKER_PATH}" ];then
    echo "already installed"
else
    echo "not installed"
fi

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y iptables-services docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
systemctl enable iptables