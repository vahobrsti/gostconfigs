#!/bin/bash
apt install curl docker docker.io redis-server zip git unzip zip net-tools -y

#ipv6
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p
nano /etc/netplan/99-frantech-ipv6.yaml
netplan apply

#ntopng installation
docker run -itd -p 3000:3000  --net=host  public.ecr.aws/y2f4h6b6/ntop:latest -i eth0 --community

#ca uptate
cp config/somimobile.com/fullchain.cer /usr/local/share/ca-certificates/ca.crt
update-ca-certificates

# gost installation
wget https://github.com/go-gost/gost/releases/download/v3.0.0-rc8/gost_3.0.0-rc8_linux_amd64.tar.gz
tar xvzf gost_3.0.0-rc8_linux_amd64.tar.gz
mv gost /usr/local/bin/gost

# dnscrypt configurations
wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.1.4/dnscrypt-proxy-linux_x86_64-2.1.4.tar.gz
tar xvzf dnscrypt-proxy-linux_x86_64-2.1.4.tar.gz
mv linux-x86_64 /opt/dnscrypt-proxy
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









#haproxy
apt install --no-install-recommends software-properties-common -y
add-apt-repository ppa:vbernat/haproxy-2.8 -y
apt update
apt install haproxy=2.8.\* -y
cp ./gostconfigs/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy
systemctl status haproxy