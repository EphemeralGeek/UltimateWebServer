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
echo "127.0.0.1 $NextSub.$Domain" >> /etc/hosts
echo "127.0.0.1 $FriendicaSub.$Domain" >> /etc/hosts
mkdir /etc/nginx/$Domain
mkdir /etc/nginx/$Domain$MatrixSub
mkdir /etc/nginx/$Domain$FriendicaSub
mkdir /etc/nginx/$Domain$NextSub
#Pulling dependancies
wget -qO - https://matrix.org/packages/debian/repo-key.asc | sudo apt-key add -
add-apt-repository https://matrix.org/packages/debian/
apt -y update && apt -y upgrade && apt -y install nginx certbot
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
    apt -y install matrix-synapse letsencrypt nginx software-properties-common
    systemctl enable matrix-synapse.service nginx.service
    sed -i 's/enable_registration: False/enable_registration: True/g' /etc/matrix-synapse/homeserver.yaml
    systemctl restart matrix-synapse.service
    systemctl stop nginx.service
    certbot certonly --rsa-key-size 2048 --standalone --agree-tos --no-eff-email --email $Email -d $MatrixSub.$Domain
    
    systemctl start nginx.service
    systemctl enable nginx.service}
#**********************************
# Installs and configures Nextcloud
#**********************************
Install_NextCloud (){
    echo "Downlaoding Nextcloud..."
    cd /etc/nginx/$NextSub.$Domain/
    curl https://download.nextcloud.com/server/installer/setup-nextcloud.php
    echo "Nextcloud downlaoded."
    #nginx config appending and certbot goes here
}
#*********************************
# Checks which services to install
#*********************************
echo "Stand by to answer a few questions, and do a little configuration."
read -n1 -r -p "Press any key to continue..." key
clear; echo "What servers do you want to install?\n1. Nextcloud\n2. Matrix (Synapse)\n3. Friendica\n4. All"
read -n1 -p "\nEnter your choice here (4):" install 

case $install
    1)
      Install_NextCloud
    2)
      Install_Synapse
    3)
      Install_Friendica
    4)
      Install_Synapse
      Install_Friendica
      install_NextCloud
    *)
        echo "invalid input... $install"
        exit 1
esac

clear; echo "Configuration complete :), wait for the server to reboot and verify functionality"
read -n1 -r -p "Press any key to exit..." key
reboot
