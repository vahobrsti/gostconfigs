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
  # Check if PAT environment variable exists
  if [[ -z "${PAT}" ]]; then
    echo "PAT environment variable is not set."
    read -p "Enter your GitHub personal access token (PAT): " PAT
    echo
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
  read -p "Enter the password to encrypt the zip file: " password

  # Specify the path to the zip file
  zip_file="gostconfigs/config.zip"

  # Extract the zip file using the provided password
  echo "Extracting $zip_file..."
  unzip -P "$password" "$zip_file"

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

    # Move the somimobile.com file
    mv somimobile.com /etc/

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
    # Add AdGuard Home installation command here
    ;;
  3)
    echo "Performing ocserv installation..."
    # Add ocserv installation command here
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

# Delete the gostconfigs directory if it exists
if [ -d "gostconfigs" ]; then
  rm -rf "gostconfigs"
fi
# Clone the repository
git clone https://github.com/vahobrsti/gostconfigs

echo "Select an option:"
echo "1. Create backup of config folder"
echo "2. server configurations"

read -p "Enter your choice: " choice
echo

case $choice in
1)
  create_backup
  ;;
2)
  server_installation
  ;;
*)
  echo "Invalid choice"
  exit 1
  ;;
esac
