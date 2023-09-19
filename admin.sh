#!/bin/bash

create_backup() {
  if [ -d "config" ]; then
    # If it exists, delete it
    rm -rf "config"
  fi
  SOURCE="config"
  DESTINATION="config.zip"

  # Prompt the user to enter the password
  read -p "Enter the password to encrypt the zip file: " PASSWORD
  echo
  # Check if PAT file  exists
  PAT_FILE="pat.txt"

  if [[ -f "${PAT_FILE}" ]]; then
    PAT=$(cat "${PAT_FILE}")
  else
    read -p "Enter your GitHub personal access token (PAT): " PAT
    echo "${PAT}" >"${PAT_FILE}"
  fi

  mkdir "$SOURCE"
  cp /etc/x-ui/x-ui.db "$SOURCE/"
  cp /usr/local/x-ui/bin/config.json "$SOURCE/"
  cp /etc/ocserv/ocserv.conf "$SOURCE/"
  cp /etc/ocserv/ocpasswd "$SOURCE/"
  cp /opt/AdGuardHome/AdGuardHome.yaml "$SOURCE/"
  iptables-save >>"$SOURCE/rules.v4"
  cp -r /etc/somimobile.com "$SOURCE/"

  # Create the encrypted zip file
  zip -e -r -P "$PASSWORD" "$DESTINATION" "$SOURCE"

  # Copy and override the config.zip in gostconfigs folder
  cp -f "$DESTINATION" gostconfigs/

  # Stage the changes
  cd gostconfigs || exit 1
  git add config.zip

  # Commit the changes with the specified message format
  timestamp=$(date +'%Y-%m-%d: %H')
  git commit -m "chore(backup): date $timestamp"
  # Push the changes to GitHub
  git push "https://vahobrsti:${PAT}@github.com/vahobrsti/gostconfigs"

  # Clean up the temporary folder
  cd .. && rm -rf "$SOURCE" gostconfigs

}

server_installation() {
  # Check if "password.txt" exists
  if [[ -f "password.txt" ]]; then
    # Read the password from the file
    password=$(cat "password.txt")
  else
    # Prompt the user to enter the password and store it in a variable
    read -p "Enter the password to extract the zip file: " password

    # Save the password to "password.txt" file
    echo "$password" >"password.txt"
  fi

  if ! command -v zip &>/dev/null; then
    echo "zip command is not found. Installing zip..."
    sudo apt-get install -y zip
  fi

  if ! command -v unzip &>/dev/null; then
    echo "unzip command is not found. Installing unzip..."
    sudo apt-get install -y unzip
  fi
  # Check if netstat command exists
  if ! command -v netstat &>/dev/null; then
    # Install net-tools package
    sudo apt-get update
    sudo apt-get install net-tools -y
  fi

  echo "zip, unzip and net-tools are installed."

  # Specify the path to the zip file
  zip_file="gostconfigs/config.zip"

  # Extract the zip file using the provided password
  echo "Extracting $zip_file..."
  unzip -o -P "$password" "$zip_file"

  echo "Extraction completed."
  # Prompt user for action selection
  echo "Select an action to perform:"
  echo "1. x-ui installation"
  echo "2. AdGuard Home installation"
  echo "3. ocserv installation"
  echo "4. Change SSH port to 422"
  echo "5. Firewall configuration"

  read -p "Enter your choice (1-5): " choice

  # Perform action based on user's choice
  case $choice in
  1)
    echo "Performing x-ui installation..."
    # Move into the extracted config directory
    cd config || exit

    # Perform x-ui installation
    # Download and execute the installation script
    bash <(curl -Ls https://raw.githubusercontent.com/sudospaes/x-ui/master/install.sh)
    # Move the somimobile.com certs
    if [ ! -d /etc/somimobile.com ]; then
      mv somimobile.com /etc/
      echo "certs moved successfully!"
    else
      echo "Directory /etc/somimobile.com already exists. No action taken."
    fi
    # Copy the x-ui.db file
    cp x-ui.db /etc/x-ui/x-ui.db

    # Copy the config.json file
    cp config.json /usr/local/x-ui/bin/config.json

    # Restart x-ui service
    systemctl restart x-ui

    echo "x-ui installation completed."
    ;;
  2)
    echo "Performing AdGuard Home installation..."
    # Move into the extracted config directory
    cd config || exit
    # Move the somimobile.com certs
    if [ ! -d /etc/somimobile.com ]; then
      mv somimobile.com /etc/
      echo "certs moved successfully!"
    else
      echo "Directory /etc/somimobile.com already exists. No action taken."
    fi
    # Download and execute the installation script for AdGuard Home
    curl -sSL https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

    # Copy the AdGuardHome.yaml file
    cp AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml

    # Stop AdGuard Home service
    /opt/AdGuardHome/AdGuardHome -s stop

    # Create directory for systemd configuration
    mkdir /etc/systemd/resolved.conf.d
    cd /etc/systemd/resolved.conf.d || exit

    # Create adguardhome.conf with DNS configuration
    echo "[Resolve]" >>adguardhome.conf
    echo "DNS=127.0.0.1" >>adguardhome.conf
    echo "DNSStubListener=no" >>adguardhome.conf

    # Backup and replace resolv.conf with a symbolic link
    mv /etc/resolv.conf /etc/resolv.conf.backup
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # Reload and restart systemd-resolved service
    systemctl reload-or-restart systemd-resolved

    # Restart AdGuard Home service
    /opt/AdGuardHome/AdGuardHome -s restart
    echo "AdGuard Home installation completed."
    ;;
  3)
    echo "Performing ocserv installation..."

    # Clone the ocserv repository
    git clone https://gitlab.com/openconnect/ocserv.git
    cd ocserv || exit
    apt install -y libgnutls28-dev libev-dev autoconf automake libpam0g-dev liblz4-dev libseccomp-dev \
      libreadline-dev libnl-route-3-dev libkrb5-dev libradcli-dev \
      libcurl4-gnutls-dev libcjose-dev libjansson-dev liboath-dev \
      libprotobuf-c-dev libtalloc-dev libhttp-parser-dev protobuf-c-compiler \
      gperf nuttcp lcov libuid-wrapper libpam-wrapper libnss-wrapper \
      libsocket-wrapper gss-ntlmssp iputils-ping \
      gawk gnutls-bin iproute2 yajl-tools tcpdump freeradius ocserv

    # Build and install ocserv
    autoreconf -fvi
    ./configure && make && make install

    # Update the ocserv service path in the systemd configuration
    sed -i "s/ExecStart=\/usr\/sbin\/ocserv/ExecStart=\/usr\/local\/sbin\/ocserv/" /lib/systemd/system/ocserv.service
    cd ./../config || exit
    # Move the somimobile.com certs
    if [ ! -d /etc/somimobile.com ]; then
      mv somimobile.com /etc/
      echo "certs moved successfully!"
    else
      echo "Directory /etc/somimobile.com already exists. No action taken."
    fi
    server_ip=$(hostname -I | awk '{print $1}')
    sed -i "s/^dns = .*/dns = $server_ip/" ocserv.conf
    cp ocserv.conf /etc/ocserv/
    cp ocpasswd /etc/ocserv/
    # enable ip forwarding
    echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/60-custom.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/60-custom.conf
    sudo sysctl -p /etc/sysctl.d/60-custom.conf
    # Find the main network interface
    net_interface=$(ip route | awk '/default/ {print $5}')
    # Use the network interface in the iptables command
    iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o "$net_interface" -j MASQUERADE

    systemctl daemon-reload
    systemctl restart ocserv
    systemctl status ocserv
    echo "ocserv installation completed."

    ;;
  4)
    echo "Changing SSH port to 422..."
    # Add SSH port change command here
    ;;
  5)
    echo "Performing firewall configuration..."
    # Add firewall configuration command here
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
  esac

  echo "Action completed."

}

synchronize_xui() {
  # Password retrieval logic
  if [[ -f "password.txt" ]]; then
    password=$(cat "password.txt")
  else
    read -p "Enter the password to extract the zip file: " password
    echo "$password" >"password.txt"
  fi

  # Specify the path to the zip file
  zip_file="gostconfigs/config.zip"

  # Extract the zip file using the provided password
  echo "Extracting $zip_file..."
  unzip -o -P "$password" "$zip_file"

  # File copy and service restart
  cp config/config.json /usr/local/x-ui/bin/config.json
  cp config/x-ui.db /etc/x-ui/x-ui.db
  systemctl restart x-ui

#  cp config/ocserv.conf /etc/ocserv/
#  cp config/ocpasswd /etc/ocserv/
#
#  systemctl restart ocserv
}

# Check if the gostconfigs directory exists
if [ -d "gostconfigs" ]; then
  # Change into the gostconfigs directory
  cd "gostconfigs"

  # Perform a git pull to update the repository
  git reset --hard
  git pull

  # Go back to the original directory
  cd -
else
  # Clone the repository
  git clone https://github.com/vahobrsti/gostconfigs
fi
echo "Select an option:"
echo "1. Create backup of config folder"
echo "2. server configurations"
echo "3. Sync the configs"

read -p "Enter your choice: " choice
echo

case $choice in
1)
  create_backup
  ;;
2)
  server_installation
  ;;
3)
  synchronize_xui
  ;;
*)
  echo "Invalid choice"
  exit 1
  ;;
esac
