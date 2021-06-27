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
