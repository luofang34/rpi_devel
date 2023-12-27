#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Clean up: Delete the downloaded tar.gz and the extracted folder
cleanup() {
    echo "Performing cleanup operations..."
    rm -rf "${FILENAME}"
    rm -rf "frp_${VERSION}_${OS}_${TRANSLATED_ARCH}"
    echo "Cleanup complete."
}

# Trap command to catch exits and execute cleanup function
trap cleanup EXIT

# Ask user for machine name
read -p "Enter machine name (Press Enter for default 'rpi0'): " machine_name

# Set default value if input is empty
if [ -z "$machine_name" ]; then
    machine_name="rpi0"
fi

echo "Machine name is set to: $machine_name"

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
VERSION_TAG=$(wget -qO- $RELEASES_PAGE | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' | head -n 1)
VERSION=${VERSION_TAG:1}  # Strip the 'v' from the version tag

echo "Latest version: $VERSION"

# Check if a version number was found
if [ -z "$VERSION" ]; then
    echo "No version number found on the releases page."
    exit 1
fi

# Construct the download URL with the latest version
FILENAME="frp_${VERSION}_${OS}_${TRANSLATED_ARCH}.tar.gz"
URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION_TAG/$FILENAME"

echo "Download URL: $URL"

# Check if a URL was found
if [ -z "$URL" ]; then
    echo "No download URL found for the current OS and architecture."
    exit 1
fi

# Download the file
curl -L $URL -o "${FILENAME//\*/}"

# Unzip the downloaded file
if tar -zxvf "${FILENAME}"; then
    echo "Uzip complete."
else
    echo "unzip failed."
    exit 1
fi

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


sudo apt-get update -y
sudo apt-get dist-upgrade -y

PREFERENCE="new"

# Update and Upgrade Packages
export DEBIAN_FRONTEND=noninteractive
if [ "$PREFERENCE" = "keep" ]; then
    sudo apt-get update
    sudo apt-get -o Dpkg::Options::="--force-confold" --force-yes -y upgrade
elif [ "$PREFERENCE" = "new" ]; then
    sudo apt-get update
    sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes -y upgrade
else
    echo "Invalid preference set. Please choose 'keep' or 'new'."
    exit 1
fi

# Install X11 server
sudo apt-get install x11-apps -y

# Backup the original sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Add AllowTcpForwarding and X11Forwarding settings
if ! grep -q "^AllowTcpForwarding" /etc/ssh/sshd_config; then
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
else
    sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config
fi

if ! grep -q "^X11Forwarding" /etc/ssh/sshd_config; then
    echo "X11Forwarding yes" >> /etc/ssh/sshd_config
else
    sed -i 's/^X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
fi

# Restart SSH service
sudo systemctl restart sshd

# Install Python 3.9
sudo apt-get install -y git make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
curl https://pyenv.run | bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
source ~/.bashrc

pyenv update

# Find the latest Python 3.9.x version
LATEST_PY39_VERSION=$(pyenv install --list | grep -Eo ' 3\.9\.[0-9]+$' | tail -1 | tr -d '[:space:]')

if [ -z "$LATEST_PY39_VERSION" ]; then
    echo "No Python 3.9.x version found"
    exit 1
else
    echo "Latest Python 3.9 version available is: $LATEST_PY39_VERSION"
fi

if pyenv install $LATEST_PY39_VERSION; then
    echo "Python 3.9 installed successfully."
else
    echo "Python 3.9 installation failed."
    exit 1
fi
pyenv global $LATEST_PY39_VERSION

git clone https://github.com/EdjeElectronics/TensorFlow-Lite-Object-Detection-on-Android-and-Raspberry-Pi.git
mv TensorFlow-Lite-Object-Detection-on-Android-and-Raspberry-Pi tflite1
cd tflite1

sudo pip3 install matplotlib virtualenv
source tflite1-env/bin/activate
bash get_pi_requirements.sh

exit 0

EOS