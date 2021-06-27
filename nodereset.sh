#!/bin/bash

set -e
kubeadm reset
rm /etc/cni/net.d/*
rm /root/.kube/config
