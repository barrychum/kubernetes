#!/bin/sh

kubectl taint nodes $HOSTNAME node-role.kubernetes.io/master=:NoSchedule
