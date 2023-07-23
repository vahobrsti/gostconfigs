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
  echo "Enter the password for the encrypted zip file:"
  read -p "Enter the password to encrypt the zip file: " password

  # Specify the path to the zip file
  zip_file="gostconfigs/config.zip"

  # Extract the zip file using the provided password
  echo "Extracting $zip_file..."
  unzip -P "$password" "$zip_file"

  echo "Extraction completed."

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
