#!/bin/bash

#make a backup
# Check if the directory exists





apt install curl docker docker.io redis-server zip git unzip zip -y
docker run -itd -p 3000:3000  --net=host ntop/ntopng:stable -i eth0 --community

#ca uptate

cp /etc/somimobile.com/fullchain.cer /usr/local/share/ca-certificates/ca.crt
update-ca-certificates


# gost
wget https://github.com/go-gost/gost/releases/download/v3.0.0-rc8/gost_3.0.0-rc8_linux_amd64.tar.gz
tar xvzf gost_3.0.0-rc8_linux_amd64.tar.gz
mv gost /usr/local/bin/gost



# dnscrypt configurations

wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.1.4/dnscrypt-proxy-linux_x86_64-2.1.4.tar.gz
tar xvzf dnscrypt-proxy-linux_x86_64-2.1.4.tar.gz
mv linux-x86_64 /opt/dnscrypt-
cp gostconfigs/dnscrypt-proxy.toml /opt/dnscrypt-proxy
systemctl stop systemd-resolved
systemctl disable systemd-resolved
apt-get remove resolvconf
apt-get remove dnsmasq
cp /etc/resolv.conf /etc/resolv.conf.backup
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
echo "options edns0" >> /etc/resolv.conf

/opt/dnscrypt-proxy/dnscrypt-proxy -service install
/opt/dnscrypt-proxy/dnscrypt-proxy -service start



#backup







#haproxy
apt install --no-install-recommends software-properties-common -y
add-apt-repository ppa:vbernat/haproxy-2.8 -y
apt update
apt install haproxy=2.8.\* -y
cp ./gostconfigs/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy