#!/bin/bash

userK8sConfigDir="${HOME}/.kube"
adminK8sConfigDir="/etc/kubernetes"

mkdir -p "${userK8sConfigDir}"
sudo cp -i "${adminK8sConfigDir}/admin.conf" "${userK8sConfigDir}/config" 
sudo chown "$(id -u)":"$(id -g)" "${userK8sConfigDir}/config"
