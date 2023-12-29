# Detect real username
if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

# Install 'expect' if not already installed
if ! command -v expect &> /dev/null
then
    sudo apt-get update
    sudo apt-get install -y expect
fi



#Add the Coral package repository to your apt-get distribution list by issuing the following commands:
cd /home/$real_user/tflite1
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
#sudo apt-get install libedgetpu1-max
# Define the command to run that triggers the prompt
PACKAGE_INSTALL_COMMAND="sudo apt-get install -y libedgetpu1-max"

# Use 'expect' to automate the interaction
/usr/bin/expect <<EOF
spawn $PACKAGE_INSTALL_COMMAND
expect "Configuring libedgetpu1-max"
send "\033[C"
send "\r"
expect eof
EOF

echo "Installation complete."

mkdir Sample_TFLite_model

wget https://dl.google.com/coral/canned_models/mobilenet_ssd_v2_coco_quant_postprocess_edgetpu.tflite
mv mobilenet_ssd_v2_coco_quant_postprocess_edgetpu.tflite Sample_TFLite_model/edgetpu.tflite