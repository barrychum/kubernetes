cat > $HOME/nodeinit.sh <<\EOF
#!/bin/bash
set -e

echo "Calico or Flannel"
read cni

kubeadm init --pod-network-cidr=10.244.0.0/16
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

if [[ $cni = [Cc] ]]
then
  kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
#  curl https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml -O
#  kubectl create -f custom-calico.yaml

cat <<\EOS | kubectl create -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOS

else
  kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/kube-flannel.yml

# https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
  kubectl apply -f https://raw.githubusercontent.com/barrychum/kubernetes/main/components.yaml
fi

kubectl taint nodes --all node-role.kubernetes.io/master-
EOF
chmod +x $HOME/nodeinit.sh

cat > $HOME/custom-calico.yaml <<\EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

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

cat > $HOME/instingress.sh <<\EOF
#!/bin/sh
git clone https://github.com/nginxinc/kubernetes-ingress/
cd kubernetes-ingress/deployments

kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml

kubectl apply -f common/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/ingress-class.yaml

kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml

kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml

kubectl apply -f daemon-set/nginx-ingress.yaml

kubectl get pods --namespace=nginx-ingress
EOF
chmod +x $HOME/instingress.sh


cat > $HOME/instmetallb.sh <<\EOF

# https://opensource.com/article/20/7/homelab-metallb
# https://metallb.universe.tf/installation/

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# https://metallb.universe.tf/configuration/
#      - 192.168.38.128/25

cat <<EOS | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: address-pool-1
      protocol: layer2
      addresses:
      - 192.168.38.60-192.168.38.65
EOS

EOF
chmod +x $HOME/instmetallb.sh

