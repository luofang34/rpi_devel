#!/bin/bash

# exit on error
set -e

conda update -c conda-forge libstdcxx-ng -y
# Update and upgrade
sudo apt update
#sudo apt upgrade -y # this will break the system. Do not run this command

sudo apt install -y libcamera0.3=0.3.0+rpt20240617-1 
sudo apt install -y libcamera-dev
pip install rpi-libcamera

# install libkms++ and rpi-kms
sudo apt install -y libkms++-dev libfmt-dev libdrm-dev
pip install rpi-kms

wget -O install_pivariety_pkgs.sh https://github.com/ArduCAM/Arducam-Pivariety-V4L2-Driver/releases/download/install_script/install_pivariety_pkgs.sh
chmod +x install_pivariety_pkgs.sh
./install_pivariety_pkgs.sh -p libcamera_dev
./install_pivariety_pkgs.sh -p libcamera_apps

# reinstall python-opencv
pip uninstall opencv-python
pip install opencv-python