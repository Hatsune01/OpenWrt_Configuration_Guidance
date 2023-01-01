#!/bin/bash

# Created by RealBrandon, on 13 April 2022

echo ""
echo ""
echo ""
echo "Please run this script as root on a debian-based distro, where a LAMP stack has been set up."
echo "Have you added the following repo to your apt repo list?"
echo "deb https://download.webmin.com/download/repository sarge contrib [y/N]"
read add_repo_result
echo ""

if [ "$add_repo_result" = "" ] || [ "$add_repo_result" = "n" ] || [ "$add_repo_result" = "N" ]
then
    # Add webmin repo to /etc/apt/sources.list.d
    echo "Adding webmin apt repo..."
    mkdir /etc/apt/sources.list.d
    echo "# webmin apt repo" > /etc/apt/sources.list.d/webmin.list
    echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list.d/webmin.list
    echo "Webmin apt repo added"
    echo ""

elif [ "$add_repo_result" = "y" ] || [ "$add_repo_result" = "Y" ]
then
    :

else
    echo "Sorry, your input is invalid. Please restart the script."
    echo ""
    exit

fi

echo "Are you running Debian 11, Ubuntu 22.04 or higher? [y/N]"
read distro_result
echo ""

# Install necessary packages
echo "Installing necessary packages..."
echo ""
apt install -y wget gnupg2
echo ""
echo "Packages installed."
echo ""

# Fetch and install GPG key
echo "Importing GPG key for the Webmin repo..."
cd /root
wget https://download.webmin.com/jcameron-key.asc
 
if [ "$distro_result" = "" ] || [ "$distro_result" = "n" ] || [ "$distro_result" = "N" ]
then
    # For older distros
    apt-key add jcameron-key.asc 

elif [ "$distro_result" = "y" ] || [ "$distro_result" = "Y" ]
then
   
    # For newer distros
    cat jcameron-key.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/jcameron-key.gpg

else
    echo "Sorry, your input is invalid. Please restart the script."
    echo ""
    exit

fi

echo "GPG key imported." 
echo "Starting webmin installation..."
echo ""

apt install -y apt-transport-https
apt update
apt install -y webmin

echo ""
echo "Webmin installed."
echo ""

/etc/webmin/start
echo "Checking Webmin status..."
systemctl daemon-reload
systemctl status webmin
echo ""
