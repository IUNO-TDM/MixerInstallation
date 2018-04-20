#!/bin/bash


mixer_user=`whoami`
mixer_installation_folder="MixerInstallation"
mixer_installation_branch="master"
license_manager_folder="LicenseManager"
license_manager_branch="master"

mixer_control_folder="MixerControl"
mixer_control_branch="stable"

pump_control_folder="PumpControl"

payment_service_folder="PaymentService"
payment_service_branch="stable"

echo "MIXER_UPDATE"


echo "============================"
echo "Stopping all services"
echo "============================"

pm2 stop all

echo "============================"
echo "Deleting log files"
echo "============================"
rm -r /home/$mixer_user/.pm2/logs

echo "============================"
echo "Installing / Upgrading Raspbian packages"
echo "============================"
sudo apt-get update
sudo apt-get upgrade -y

echo "============================"
echo "Updating node, npm, pm2"
echo "============================"

export NVM_DIR=$HOME/.nvm;
source $HOME/.nvm/nvm.sh;
nvm install 9.9.0
npm install -g npm
npm install pm2 -g
pm2 install pm2-logrotate@2.2.0
pm2 set pm2-logrotate:retain 10

echo "============================"
echo "Update MixerInstallation files"
echo "============================"
cd /home/$mixer_user/$mixer_installation_folder
git reset --hard
git checkout $mixer_installation_branch
git pull origin $mixer_installation_branch

echo "==================================="
echo "Update Payment Service"
echo "==================================="s

cd /home/$mixer_user/$payment_service_folder
git reset --hard
git checkout $payment_service_branch
git pull origin $payment_service_branch
mvn clean package



echo "==================================="
echo "Update MixerControl"
echo "==================================="
cd /home/$mixer_user/$mixer_control_folder
git reset --hard
git checkout $mixer_control_branch
git pull origin $mixer_control_branch
cd /home/$mixer_user/$mixer_control_folder/MixerControl-app
npm install
npm install -g @angular/cli
npm run build

echo "Finished installing MixerControl"

echo "==================================="
echo "Install license manager"
echo "==================================="

cd /home/$mixer_user
mkdir -p $license_manager_folder
cp -f /home/$mixer_user/$mixer_installation_folder/LicenseManager /home/$mixer_user/$license_manager_folder
sudo chmod a+x /home/$mixer_user/$license_manager_folder/LicenseManager

echo "Finished installing LicenseManager"

echo "==================================="
echo "Install PumpControl"
echo "==================================="

cd /home/$mixer_user
mkdir -p $pump_control_folder
cp -f /home/$mixer_user/$mixer_installation_folder/PumpControl /home/$mixer_user/$pump_control_folder
cd /home/$mixer_user/$pump_control_folder

sudo chmod a+x PumpControl
sudo chown root PumpControl
sudo chgrp kmem PumpControl
sudo chmod ug+s PumpControl

echo "Finished Updating"

