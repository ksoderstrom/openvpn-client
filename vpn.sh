#!/bin/bash

set -o nounset

if [ ! -f /vpn/client.ovpn ];
then
    echo "Configuration file not found! Add as /vpn/client.ovpn" && exit 1
fi

echo "$VPN_USER" > /vpn/authfile
echo "$VPN_PASS" >> /vpn/authfile
chmod 0600 /vpn/authfile

mkdir -p /dev/net
[[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200
exec sg vpn -c "openvpn --verb 5 --cd /vpn --config /vpn/client.ovpn --auth-user-pass /vpn/authfile"
