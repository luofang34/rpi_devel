#!/bin/bash

# Ask user for machine name
read -p "Enter the machine name: " machine_name

# Script to download, install, and configure 'frp' from GitHub based on system architecture and OS
GITHUB_REPO="fatedier/frp"
RELEASES_PAGE="https://github.com/$GITHUB_REPO/releases/latest"

# Function to translate architecture names
translate_architecture() {
    local arch=$1

    case $arch in
        aarch64)
            echo "arm64"
            ;;
        x86_64)
            echo "amd64"
            ;;
        *)
            echo $arch
            ;;
    esac
}

# Detect the architecture and OS
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Translate architecture if necessary
TRANSLATED_ARCH=$(translate_architecture $ARCH)

echo "Detected OS: $OS, Architecture: $ARCH, Translated Architecture: $TRANSLATED_ARCH"

# Fetch the latest version number from GitHub releases page
VERSION=$(curl -sL $RELEASES_PAGE | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' | head -n 1)

echo "Latest version: $VERSION"

# Check if a version number was found
if [ -z "$VERSION" ]; then
    echo "No version number found on the releases page."
    exit 1
fi

# Construct the download URL with the latest version
FILENAME="frp_${VERSION}_${OS}_${TRANSLATED_ARCH}.tar.gz"
URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/$FILENAME"

echo "Download URL: $URL"

# Download the file
curl -L $URL -o "${FILENAME}"

echo "Download complete."

# Unzip the downloaded file
tar -zxvf "${FILENAME}"

# Check for frpc executable and move it to /usr/bin
if [ -f "./frp_${VERSION}_${OS}_${TRANSLATED_ARCH}/frpc" ]; then
    echo "Moving frpc to /usr/bin/"
    sudo mv "./frp_${VERSION}_${OS}_${TRANSLATED_ARCH}/frpc" /usr/bin/
else
    echo "frpc executable not found."
    exit 1
fi

# Create the configuration directory if it doesn't exist
sudo mkdir -p /etc/frp

# Create the configuration with the user-provided machine name
sudo cat <<EOF >/etc/frp/frpc.toml
serverAddr = "luofang.org"
serverPort = 7000
 
[[proxies]]
name = "$machine_name"
type = "tcpmux"
multiplexer = "httpconnect"
customDomains = ["$machine_name.luofang.org"]
localIP = "127.0.0.1"
localPort = 22
EOF

echo "Configuration file created at /etc/frp/frpc.toml."

# Create a systemd service file for FRP
cat <<EOF >/etc/systemd/system/frpc.service
[Unit]
Description=Frp Client Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/frpc -c /etc/frp/frpc.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the FRP service
sudo systemctl daemon-reload
sudo systemctl enable frpc.service
sudo systemctl start frpc.service

echo "FRP client service created and started."

echo "frpc installed and configured successfully."

EOS