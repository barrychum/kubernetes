cat > $HOME/nodeinit.sh <<\EOF
#!/bin/bash
set -e
kubeadm init --pod-network-cidr=10.244.0.0/16
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
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

echo -n "Are you sure to delete this node (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then

    if [[ $(kubectl get nodes | grep $HOSTNAME | grep -L "master") ]] ; then
        kubectl drain $HOSTNAME --delete-emptydir-data --force --ignore-daemonsets
        echo "This is a workder node.  This has been removed from cluster"
    fi

    kubeadm reset --force

    rm /etc/cni/net.d/*
    rm $HOME/.kube/config
    rm -rf /root/.kube/cache
else
    echo "Cancelled"
fi



EOF
chmod +x $HOME/nodereset.sh


cat > $HOME/nodejoin.sh <<\EOF
#!/bin/bash
clear -x
echo "What is the master node IP "
read masterip

echo "What is the master node password "
read -s masterpass
clear -x

sshpass -p $masterpass scp root@$masterip:/etc/kubernetes/admin.conf $HOME/.kube/config
execcmd=$(sshpass -p $masterpass ssh root@$masterip kubeadm token create --print-join-command --ttl=1m)
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

cat > $HOME/disableScheduling.sh <<\EOF
#!/bin/sh
hn=$(hostname)
kubectl taint nodes $hn node-role.kubernetes.io/master=:NoSchedule
EOF
chmod +x $HOME/disableScheduling.sh

cat > $HOME/enableScheduling.sh <<\EOF
#!/bin/sh
hn=$(hostname)
# kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes $hn node-role.kubernetes.io/master-
EOF
chmod +x $HOME/enableScheduling.sh

