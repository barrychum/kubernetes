cat > $HOME/nodeinit.sh <<\EOF
#!/bin/bash
set -e
kubeadm init --pod-network-cidr=10.244.0.0/16
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/stellarhub/kubernetes/main/kube-flannel.yml

# https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
EOF
chmod +x $HOME/nodeinit.sh


cat > $HOME/nodereset.sh <<\EOF
#!/bin/bash
set -e
if [[ $(kubectl get nodes | grep $HOSTNAME | grep -L "master") ]]
then
kubectl drain $HOSTNAME --delete-emptydir-data --force --ignore-daemonsets
fi

kubeadm reset
rm /etc/cni/net.d/*
rm $HOME/.kube/config
rm -rf /root/.kube/cache
EOF
chmod +x $HOME/nodereset.sh


cat > $HOME/nodejoin.sh <<\EOF
#!/bin/bash
echo "What is the master node IP "
read masterip

scp root@$masterip:/etc/kubernetes/admin.conf $HOME/.kube/config
execcmd=$(ssh root@$masterip kubeadm token create --print-join-command --ttl=1m)
$execcmd

kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml

kubectl label node $HOSTNAME node-role.kubernetes.io/worker=worker
kubectl get nodes

EOF
chmod +x $HOME/nodejoin.sh


cat > $HOME/exposeNode.sh <<\EOF
#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

clear -x
echo -e "${bold}Existing deployments${normal}"
dps=$(kubectl get deployment | grep -v "UP-TO-DATE" | awk '{print $1}')
echo $dps
echo

printf "Which deployment you want to expose : "
read -r dp

printf "Please enter a new NodePort service name : "
read -r svcname

kubectl expose deployment $dp --type=NodePort --name=$svcname

a=$(kubectl describe services $svcname | grep NodePort: | awk '{print $3}' | awk -F'[/]' '{print $1}')
b=$(kubectl cluster-info | grep "control plane" | awk '{print $7}')
d=$(echo $b | awk -F: '{print $2}')
echo
echo -e "${bold}You can access the new service via the following${normal}"
echo http:$d:$a
echo
echo -e "\033[1mAll existing NodePort services\033[0m"
kubectl get services | grep NodePort | awk '{print $1 "\t" $5}'
EOF
chmod +x $HOME/exposeNode.sh
