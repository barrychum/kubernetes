#!/bin/bash
echo "What is the master node IP "
read masterip

scp root@$masterip:/etc/kubernetes/admin.conf $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml

echo

kubectl label node $HOSTNAME node-role.kubernetes.io/worker=worker
kubectl get nodes

echo

