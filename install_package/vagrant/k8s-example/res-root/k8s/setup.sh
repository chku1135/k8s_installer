#!/usr/bin/bash

export SCRIPT_PATH=${1:-~/script}
export K8S_VERSION=${2:-1.31}
export K8S_IP=${3:-192.168.0.156}
export K8S_HOST=${4:-master.k8s}

# master.k8s 라는 도메인으로 hosts 파일에 등록 함.
sudo sh -c "echo $K8S_IP $K8S_HOST >> /etc/hosts"

# Install Containerd & K8S
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo $SCRIPT_PATH/install-containerd.sh
sudo $SCRIPT_PATH/install-k8s.sh $K8S_VERSION

# K8S Node Init
sudo systemctl restart containerd
sudo systemctl restart kubelet
cat << EOF > conf.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "${K8S_IP}"
  bindPort: 6443
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: containerd
EOF
sudo kubeadm init --config=conf.yaml --v=5 > kubeinit.log && cat kubeinit.log

# Copy K8S Config
echo export KUBECONFIG=/etc/kubernetes/admin.conf >> $HOME/.bashrc

# Install Calico
sudo $SCRIPT_PATH/install-calico.sh
출처: https://tack0829.tistory.com/8 [기도의 IT 스토리:티스토리]
