#!/usr/bin/bash

export PARAM_K8S_VERSION=${1:-1.31}
export K8S_VERSION_LATEST=`curl -L -s https://dl.k8s.io/release/stable-$PARAM_K8S_VERSION.txt`
# export K8S_VERSION_LATEST=`curl -L -s https://dl.k8s.io/release/stable-1.31.txt`
# export K8S_VERSION_LATEST='v1.31.0'

export K8S_VERSION=${K8S_VERSION_LATEST:0:5}
#export K8S_VERSION=v1.31



# ---------------------------------------------------------------
# IPv4를 포워딩하여 iptables가 브리지된 트래픽을 보게 하기
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 필요한 sysctl 파라미터를 설정하면, 재부팅 후에도 값이 유지된다.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo echo '1' | sudo tee /proc/sys/net/ipv4/ip_forward

sysctl --system


# SWAP 제거
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# iptables 설정
SOURCE_FILE="/etc/sysctl.conf"
LINE_INPUT="net.bridge.bridge-nf-call-iptables = 1"
grep -qF "$LINE_INPUT" "$SOURCE_FILE"  || echo "$LINE_INPUT" | sudo tee -a "$SOURCE_FILE"

# 방화벽 등록
sudo ufw allow 179/tcp
sudo ufw allow 4789/udp
sudo ufw allow 5473/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 4149/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10255/tcp
sudo ufw allow 10256/tcp
sudo ufw allow 9099/tcp
sudo ufw allow 6443/tcp
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# apt 패키지 인덱스를 업데이트하고, Kubernetes apt 저장소가 필요로 하는 패키지를 설치합니다.
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl

# 구글 클라우드의 공개 사이닝 키를 다운로드 한다.
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 쿠버네티스 apt 리포지터리를 추가한다.
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# apt 패키지를 업데이트하고, kubelet, kubeadm, kubectl을 설치합니다.
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

# 그리고 kubelet, kubeadm, kubectl이 자동으로 업그레이드 되는 일이 없게끔 버전을 고정합니다.
sudo apt-mark hold kubelet kubeadm kubectl
# ---------------------------------------------------------------
 

 # conteaienrnetworking-plugins 설치
sudo apt install containernetworking-plugins

# Node-Shell (https://github.com/kvaps/kubectl-node-shell)
curl -LO https://github.com/kvaps/kubectl-node-shell/raw/master/kubectl-node_shell
chmod +x ./kubectl-node_shell
sudo mv ./kubectl-node_shell /usr/local/bin/kubectl-node_shell
# ----------------------------------------------------------



sudo systemctl restart kubelet
