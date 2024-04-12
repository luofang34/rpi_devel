#!/bin/bash

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install GPSD and GPSD clients
echo "Installing gpsd, gpsd-clients, and python-gps..."
sudo apt install gpsd gpsd-clients python-gps -y
sudo pip3 install gps

# Stop gpsd socket to avoid automatic start
echo "Stopping gpsd socket to avoid issues during configuration..."
sudo systemctl stop gpsd.socket
sudo systemctl disable gpsd.socket

# Configure gpsd to start on boot and set default options
echo "Configuring gpsd to start on boot with correct options..."
sudo bash -c 'cat > /etc/default/gpsd' << EOF
START_DAEMON="true"
GPSD_OPTIONS="-n"
DEVICES="/dev/ttyACM0"
USBAUTO="true"
GPSD_SOCKET="/var/run/gpsd.sock"
EOF

# Re-enable gpsd socket
echo "Re-enabling gpsd socket to start automatically..."
sudo systemctl enable gpsd.socket
sudo systemctl start gpsd.socket

# Check gpsd status
echo "Setup complete. GPSD status:"
sudo systemctl status gpsd