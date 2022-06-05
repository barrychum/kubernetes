#!/bin/bash

set -e 

# disable swap is a requirement for kubernetes  
swapoff -a
sed -e '/swap/ s/^#*/#/' -i /etc/fstab

# install all en locales for docker just in case
# dpkg-reconfigure locales
sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

# enable bridge netfilter
modprobe br_netfilter
echo 'net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/20-bridge-nf.conf
sysctl --system

apt-get update
apt-get install sudo -y
apt-get install -y apt-transport-https ca-certificates curl gnupg2


# install docker (using recommended systemd driver)
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
mkdir /etc/docker;
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -;
echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' > /etc/apt/sources.list.d/docker.list;
apt-get update;
apt-get install -y --no-install-recommends docker-ce;

# install docker (using cgroupfs, deprecated in v1.21)
# apt install docker.io -y
## export LC_CTYPE=en_HK.UTF-8
## export LC_ALL=en_HK.UTF-8
# systemctl start docker
# systemctl enable docker

# install kubernetes
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list
# next line from kubernetes.io
### curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
### echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet=1.23.1-00 kubeadm=1.23.1-00 kubectl=1.23.1-00

mkdir -p $HOME/.kube

chmod +x createscript.sh

./createscript.sh

# insall kubens tool
# apt-get install -y kubectx
cd /tmp
git clone https://github.com/ahmetb/kubectx
cp kubectx/kubectx /usr/local/bin/kubectx
cp kubectx/kubens /usr/local/bin/kubens
