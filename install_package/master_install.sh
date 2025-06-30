#!/bin/bash

#root user
#############################################################
#swapoff
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab

#bridge network
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

cat <<EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward=1
EOF
sysctl -p
cat /proc/sys/net/ipv4/ip_forward

modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

#disable firewall
systemctl stop firewalld 
systemctl disable firewalld
############################################################

#[사용자] user
# k8s insatll
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

mkdir /etc/apt/keyrings

#docker install
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io

#docker 설치 확인
sudo docker --version

#curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

#echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list 
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


#version 수정 가능
#sudo apt-get update
#sudo apt-get install kubelet=1.22.8-00 kubeadm=1.22.8-00 kubectl=1.22.8-00

sudo apt update
sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

systemctl daemon-reload
systemctl restart kubelet


# containerd 설치
sudo apt install -y containerd

# containerd 설정 파일 생성 및 수정
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# SystemdCgroup = true 로 수정 후 저장
#sudo vi /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml 

# containerd 서비스 재시작
sudo systemctl restart containerd.service
sudo systemctl enable containerd.service

# 서비스 상태 확인
#sudo systemctl status containerd.service

#control-plane initialize
#root user
kubeadm init --pod-network-cidr=192.168.0.0/16

#kubeadm join 출력
#kubeadm join 10.0.2.10:6443 --token xim0ns.0egjjtai2z2knyop \
#        --discovery-token-ca-cert-hash sha256:0b020d222c6e76e39b2733b179967e6b1889199f245fea7be55ab17056e8b42a

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config  # 쿠버네티스 설정 복사
#sudo chown $(id -u):$(id -g) $HOME/.kube/config   # 권한 부여
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
source ~/.bashrc

#확인
kubectl get nodes

#이후 calico install 진행


