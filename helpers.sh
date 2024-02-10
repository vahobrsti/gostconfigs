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
add-apt-repository ppa:vbernat/haproxy-2.9 -y
apt update
apt install haproxy=2.9.\* -y
cp ./gostconfigs/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy
systemctl status haproxy

#wstunnel
wget https://github.com/erebe/wstunnel/releases/download/v9.2.2/wstunnel_9.2.2_linux_amd64.tar.gz
tar xvzf wstunnel_9.2.2_linux_amd64.tar.gz
chmod +x wstunnel
mv wstunnel /usr/local/bin/wstunnel
nano /etc/systemd/system/wstunnel.service

systemctl daemon-reload
systemctl enable wstunnel.service
systemctl start wstunnel.service

#outline

sudo curl -sS https://get.docker.com/ | sh
sudo usermod -aG docker ubuntu
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)"
cp /etc/somimobile.com/somimobile.com.key /opt/outline/persisted-state/shadowbox-selfsigned.key
cp /etc/somimobile.com/fullchain.cer /opt/outline/persisted-state/shadowbox-selfsigned.crt

new_cert_sha256=$(openssl x509 -in /opt/outline/persisted-state/shadowbox-selfsigned.crt -noout -fingerprint -sha256 | tr --delete : | awk -F'=' '{print $2}')
sed -i "s/certSha256:.*/certSha256:$new_cert_sha256/" /opt/outline/access.txt
echo "{\"certSha256\":\"$new_cert_sha256\",\"apiUrl\":\"$(grep apiUrl /opt/outline/access.txt | cut -d ':' -f 2-)\"}"
/opt/outline/persisted-state/start_container.sh

