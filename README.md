# OpenVPN Docker

A docker container for connecting to a OpenVPN server.

## Starting the container

    sudo docker run -d \
      --cap-add=NET_ADMIN --device /dev/net/tun \
      --name vpn \
      -v /etc/localtime:/etc/localtime:ro \
      -v </some/apth/vpn>:/vpn \
      -e VPN_USER=<username> \
      -e VPN_PASS=<password> \
      -e VPN_FIREWALL=<true|false> \
      -e LOCAL_NETWORK=10.0.0.0/24 \
      --dns 8.8.8.8 --dns 8.8.4.4 \
      ksoderstrom/openvpn-client
