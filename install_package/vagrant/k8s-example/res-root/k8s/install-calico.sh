#!/usr/bin/bash

curl https://calico-v3-25.netlify.app/archive/v3.25/manifests/calico.yaml -O --insecure
sed -i -e "s|# - name: CALICO_IPV4POOL_CIDR|- name: CALICO_IPV4POOL_CIDR|g" calico.yaml
kubectl apply -f calico.yaml
rm -f ./calico.yaml
