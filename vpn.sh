#!/bin/bash

set -o nounset
set -e

if [ ! -f /vpn/client.ovpn ];
then
    echo "Configuration file not found! Add as /vpn/client.ovpn" && exit 1
fi

echo "$VPN_USER" > /vpn/authfile
echo "$VPN_PASS" >> /vpn/authfile
chmod 0600 /vpn/authfile

mkdir -p /dev/net
[[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200

ip route | grep -q "127.0.0.1" || ip route add to 127.0.0.1 dev lo

if [ "${VPN_FIREWALL:-false}" = "true" ];
then
  echo "Setting up firewall"
  network=$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')
  echo "Docker network is $network"

  iptables --version
  iptables -m owner --help

  iptables -F OUTPUT
  iptables -P OUTPUT DROP
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A OUTPUT -o tap0 -j ACCEPT
  iptables -A OUTPUT -o tun0 -j ACCEPT
  iptables -A OUTPUT -d ${network} -j ACCEPT
  iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT

  vpn_port=$(awk '/^remote / && NF ~ /^[0-9]*$/ {print $NF}' /vpn/client.ovpn | grep ^ | head -n 1 || echo 1194)
  iptables -A OUTPUT -p tcp -m tcp --dport $vpn_port -j ACCEPT
  iptables -A OUTPUT -p udp -m udp --dport $vpn_port -j ACCEPT
else
  echo "Not setting up firewall"
fi

if [ "${LOCAL_NETWORK:-false}" != "false" ];
then
  echo "Setting up local network routing"
  gateway=$(ip route | awk '/default/ {print $3}')
  ip route | grep -q "$LOCAL_NETWORK" || ip route add to $LOCAL_NETWORK via $gateway dev eth0
  if [ "${VPN_FIREWALL:-false}" = "true" ];
  then
    iptables -A OUTPUT --destination $LOCAL_NETWORK -j ACCEPT
  fi
fi

exec sg vpn -c "openvpn --verb 5 --cd /vpn --config /vpn/client.ovpn --auth-user-pass /vpn/authfile"
