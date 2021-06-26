#!/bin/bash

set -e 

# disable swap is a requirement for kubernetes  
swapoff -a
sed -e '/swap/ s/^#*/#/' -i /etc/fstab

# install all en locales for docker just in case
# dpkg-reconfigure locales
sed -i -e "s/# en_HK.UTF-8 UTF-8/en_HK.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

# enable bridge netfilter
# modprobe br_netfilter
# echo 'net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/20-bridge-nf.conf
# sysctl --system

apt-get update
apt-get install sudo -y
apt-get install -y apt-transport-https ca-certificates curl gnupg2

# install docker 
apt install docker.io -y
# export LC_CTYPE=en_HK.UTF-8
# export LC_ALL=en_HK.UTF-8
systemctl start docker
systemctl enable docker

# install kubernetes
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
### curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
### echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

# kubeadm init --pod-network-cidr=10.244.0.0/16
kubeadm init
mkdir -p $HOME/.kube
mkdir $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config

kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/master | awk 'FNR==2{print $1}') node-role.kubernetes.io/master-

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
