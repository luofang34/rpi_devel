#!/bin/bash

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

# Export the contents of the provided file to /etc/frp/frpc.toml #TBD
sudo cp "/path/to/uploaded/frpc.toml" /etc/frp/

echo "frpc installed and configured successfully."

EOF