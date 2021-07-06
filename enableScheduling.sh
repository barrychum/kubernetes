#!/bin/sh
hn=$(hostname)
# kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes $hn node-role.kubernetes.io/master-
