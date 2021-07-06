#!/bin/sh
hn=$(hostname)
kubectl taint nodes $hn node-role.kubernetes.io/master=:NoSchedule
