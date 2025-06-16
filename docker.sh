#!/bin/bash

for pkg in $(dpkg-query -W -f='${binary:Package}\n' | grep docker); do sudo apt-get purge -y $pkg; done
for pkg in containerd containerd.io runc; do sudo apt-get purge -y $pkg; done
sudo apt autoremove -y

sudo groupadd docker
sudo usermod -aG docker ${USER}

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common libssl-dev libffi-dev git wget nano

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update

sudo apt-get install -y docker-compose-v2
