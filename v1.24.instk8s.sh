#!/bin/bash

## disable swap for kubelet requirement (swap is in alpha support after v1.22)
swapoff -a
sed -e '/swap/ s/^#*/#/' -i /etc/fstab

# install all en locales for docker just in case
# dpkg-reconfigure locales
sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

## The followings are official kubernetes installation steps
## https://kubernetes.io/docs/setup/production-environment/container-runtimes/
##

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/20-k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

###############

sudo apt-get update

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl restart docker

## default docker packaged disabled cri which is required for k8s
sed -e '/disabled_plugins/ s/^#*/#/' -i /etc/containerd/config.toml
sudo systemctl restart containerd

################

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

apt list -a kubectl | grep kubectl | tac

latest=$(apt list -a kubectl | grep kubectl | tac | tail -n1 | awk '{printf "%s",$2}')

echo "Enter the version to install, or press enter to install \"$latest\""
read verinst

if [ -z "$verinst"]
then
    verinst=$latest
fi
echo "Installing version $verinst"

sudo apt-get install -y kubelet=1.24.1-00 kubeadm=1.24.1-00 kubectl=1.24.1-00
sudo apt-mark hold kubelet kubeadm kubectl

##
## https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
## 

## Official kubernetes installation steps ends here
######

mkdir -p $HOME/.kube

chmod +x createscript.sh

./createscript.sh

# insall kubens tool
# apt-get install -y kubectx
cd /tmp
git clone https://github.com/ahmetb/kubectx
cp kubectx/kubectx /usr/local/bin/kubectx
cp kubectx/kubens /usr/local/bin/kubens
