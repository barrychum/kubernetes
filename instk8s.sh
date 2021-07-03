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
apt-get install -y kubelet kubeadm kubectl

# insall kubens tool
apt-get install -y kubectx

mkdir -p $HOME/.kube

# kubeadm init  ## failed to start pods without pod-network param
## mkdir $HOME/.kube

cat > $HOME/nodeinit.sh <<EOF
#!/bin/bash

set -e

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
kubeadm init --pod-network-cidr=10.244.0.0/16
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# cp -f /etc/kubernetes/admin.conf $HOME/.kube/config

# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/stellarhub/kubernetes/main/kube-flannel.yml
# kubectl apply -f https://raw.githubusercontent.com/stellarhub/kubernetes/main/kube-flannel-rbac.yml

# install matrics server
# https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
# kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
EOF

# need to apply control plane isolation for single node environment
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
# the following find nodes with master role only
# echo 'kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/master | awk "FNR==2{print $1}") node-role.kubernetes.io/master-' >> $HOME/nodeinit.sh

chmod +x $HOME/nodeinit.sh
$HOME/nodeinit.sh


cat > $HOME/nodereset.sh <<EOF
#!/bin/bash

set -e
kubeadm reset
rm /etc/cni/net.d/*
rm $HOME/.kube/config
rm -rf /root/.kube/cache
EOF

chmod +x $HOME/nodereset.sh

# deploy metrics server with tls disabled on test server
# https://github.com/kubernetes-sigs/metrics-server/
# wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
# vi components.yaml
# kubectl apply -f components.yaml


