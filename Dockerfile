FROM debian:stable-slim
MAINTAINER Karl Söderström <karl@karlsoderstrom.com>

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -qqy --no-install-recommends iptables openvpn procps && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* && \
    addgroup --system vpn
COPY ./vpn.sh /usr/bin/

ENV VPN_USER="user" \
    VPN_PASS="pass"

VOLUME /vpn

ENTRYPOINT vpn.sh
