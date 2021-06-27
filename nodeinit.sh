#!/bin/bash

set -e
kubeadm init --pod-network-cidr=10.244.0.0/16
cp -f /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://raw.githubusercontent.com/stellarhub/kubernetes/main/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
