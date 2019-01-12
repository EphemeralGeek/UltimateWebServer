#!/bin/bash
#*******************************************************
# a simple script to configre a web suite consisting of:
#   friendica, synapse (matrix), and nextcloud
#   intended for a personal Ubuntu server 18.10
#*******************************************************
Domain=[yourdomain]
Directory=[yourdirectoryofchoice]
Email=[youremailforcertbot]
MatrixSub=[subdomainForMatrix]
FriendicaSub=[subdomainForFriendica]
NextSub=[YoursubdomainForNextcloud]


#***************
# Checks if root
#***************
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
#*****************
# some quick setup
#*****************
echo "127.0.0.1 $Domain" >> /etc/hosts
echo "127.0.0.1 $MatrixSub.$Domain" >> /etc/hosts
echo "127.0.0.1 $FriendicaSub.$Domain" >> /etc/hosts
mkdir /etc/nginx/$Domain
mkdir /etc/nginx/$Domain$MatrixSub
mkdir /etc/nginx/$Domain$FriendicaSub
#Pulling dependancies
add-apt-repository ppa:certbot/certbot
apt -y update && apt -y upgrade && apt -y install nginx certbot letsencrypt nginx software-properties-common python-certbot-nginx git curl mariadb


#*********************************
# Ensures the system is up to date
#*********************************
Update (){apt update && apt upgrade}
#*******************
# installs Friendica
#*******************
Install_Friendica (){
    echo "Downloading Friendica..."
    #Verify no further dependancies are needed, if they are put them here
    cd /var/nginx/$FriendicaSub.$Domain
    mkdir ./addon
    git clone https://github.com/friendica/friendica.git
    git clone https://github.com/friendica/friendica-addons.git ./addon
    cd ./addon/
    git pull
    echo "*/10 * * * * cd /var/apache/online/friendica; /usr/bin/php include/poller.php" >> /etc/crontab
    #cerbot stuff goes here
    echo "Friendica downloaded."}

#********************************
# Installs and configures Synapse
#********************************
Istall_Synapse (){
    echo "Downloading Synapse"
    wget -qO - https://matrix.org/packages/debian/repo-key.asc | sudo apt-key add -
    add-apt-repository https://matrix.org/packages/debian/
    apt update
    apt -y install matrix-synapse 
    systemctl start matrix-synapse && systemctl enable matrix-synapse

    sed -i 's/enable_registration: False/enable_registration: True/g' /etc/matrix-synapse/homeserver.yaml
    systemctl restart matrix-synapse.service
    systemctl stop nginx.service
    certbot certonly --rsa-key-size 2048 --standalone --agree-tos --no-eff-email --email $Email -d $MatrixSub.$Domain
    
    systemctl start nginx.service
    systemctl enable nginx.service
    echo "Synapse downloaded..."}

#***********************
# Kicks off installation
#***********************
echo "Stand by to answer a few questions, and do a little configuration."
read -n1 -r -p "Press any key to continue..." key

Install_Synapse
Install_Friendica

clear; echo "Configuration complete :), wait for the server to reboot and verify functionality"
read -n1 -r -p "Press any key to exit..." key
reboot 0
