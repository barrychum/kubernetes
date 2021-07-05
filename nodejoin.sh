#!/bin/bash
echo "What is the master node IP "
read masterip

scp root@$masterip:/etc/kubernetes/admin.conf $HOME/.kube/config
execcmd=$(ssh root@$masterip kubeadm token create --print-join-command --ttl=1m)
$execcmd

kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml

kubectl label node $HOSTNAME node-role.kubernetes.io/worker=worker
kubectl get nodes
