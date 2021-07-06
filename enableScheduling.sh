#!/bin/sh

# kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes $HOSTNAME node-role.kubernetes.io/master-
