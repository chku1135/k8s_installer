#!/bin/bash

# -----------------------------
# 1. 방화벽 기본 정책을 차단으로 변경
# -----------------------------
DEFAULT_ZONE=$(firewall-cmd --get-default-zone)

echo "[INFO] 기본 정책을 DROP으로 설정 (Zone: $DEFAULT_ZONE)"
firewall-cmd --permanent --set-target=DROP --zone=$DEFAULT_ZONE

# -----------------------------
# 2. 허용할 IP 목록 (IPv4 + IPv6)
# -----------------------------
IP_LIST=(
  "192.168.10.20"
  "192.168.10.21"
  "2001:db8::1"      # IPv6 예시
)

# -----------------------------
# 3. 허용할 포트 목록
# -----------------------------
PORT_LIST=(
  "8080/tcp"
  "9090/tcp"
  "1521/tcp"
)

# -----------------------------
# 4. 허용 규칙 추가
# -----------------------------
for ip in "${IP_LIST[@]}"; do
  if [[ "$ip" == *":"* ]]; then
    family="ipv6"
  else
    family="ipv4"
  fi

  for port_proto in "${PORT_LIST[@]}"; do
    port="${port_proto%%/*}"
    proto="${port_proto##*/}"

    echo "[ALLOW] $family $ip -> $port/$proto"
    firewall-cmd --permanent \
      --add-rich-rule="rule family=$family source address=$ip port protocol=$proto port=$port accept"
  done
done

# -----------------------------
# 5. 필수 서비스(SSH) 유지
# -----------------------------
echo "[INFO] SSH(22/tcp) 기본 허용 추가"
firewall-cmd --permanent --add-service=ssh

# -----------------------------
# 6. 적용
# -----------------------------
firewall-cmd --reload
echo "[INFO] 최종 방화벽 rich rules:"
firewall-cmd --list-rich-rules