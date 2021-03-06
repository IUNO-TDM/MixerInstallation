#!/bin/bash


mixer_user=`whoami`
mixer_installation_folder="MixerInstallation"
mixer_installation_branch="master"
license_manager_folder="LicenseManager"
license_manager_branch="master"

mixer_control_folder="MixerControl"
mixer_control_branch="master"

pump_control_folder="PumpControl"

payment_service_folder="PaymentService"
payment_service_branch="master"

echo "MIXER_INSTALLATION"



echo "============================"
echo "Installing / Upgrading Raspbian packages"
echo "============================"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y maven python-imaging libboost-all-dev libssl-dev ntp vim sl nmap lolcat cowsay
echo "Finished installing packages"

echo "============================"
echo "Installing nvm, node, pm2 "
echo "============================"

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR=$HOME/.nvm;
source $HOME/.nvm/nvm.sh;
nvm install 9.3.0
npm install pm2 -g
pm2 install pm2-logrotate
pm2 set pm2-logrotate:retain 10
echo "Finished installing nvm, node, pm2"

echo "============================"
echo "Clone installation files"
echo "============================"
cd /home/$mixer_user
git clone https://github.com/IUNO-TDM/MixerInstallation.git /home/$mixer_user/$mixer_installation_folder
cd /home/$mixer_user/$mixer_installation_folder
git reset --hard
git checkout $mixer_installation_branch
git pull origin $mixer_installation_branch

echo "Finished cloning installation files"



echo "==================================="
echo "Install Payment Service"
echo "==================================="s

cd /home/$mixer_user
git clone https://github.com/IUNO-TDM/PaymentService.git /home/$mixer_user/$payment_service_folder
cd /home/$mixer_user/$payment_service_folder
git reset --hard
git checkout $payment_service_branch
git pull origin $payment_service_branch
mvn clean package



#check if there is an existing wallet file or a backup file 

if [ -e /home/$mixer_user/.PaymentService/PaymentService.wallet ]
then
    echo "There is already a wallet. Won't initialize a new one."
else
    menu_option=$(whiptail --title "Wallet for PaymentService" --menu "The PaymentService contains a Bitcoin Wallet to store the Bitcoins earned at your machine." 25 78 16 "1" "I don't have a wallet yet. Let's create one" "2" "I have the wallet seed and want to enter it" --nocancel  3>&1 1>&2 2>&3)

    if [ $menu_option = "2" ]
    then
     mnemonics=$(whiptail --inputbox "Enter the mnemonic (e.g. \"never,use,this,seed,never,use,this,seed,never,use,this,seed\")" 8 100  --title "Enter Wallet Seed" 3>&1 1>&2 2>&3)
     creationtime=$(whiptail --inputbox "enter the creation time (e.g. 1504199300)" 8 100  --title "Enter Wallet Seed" 3>&1 1>&2 2>&3)
    else
        wallet_init_res=`mvn -q clean package exec:java -Dexec.mainClass=iuno.tdm.paymentservice.init.WalletInitializer -Dexec.args=seed`
        readarray -t lines <<< "$wallet_init_res"

        mnemonics=$(echo ${lines[0]} | sed 's/[[:space:]]//g')

        creationtime=${lines[1]}

        echo "the wallet mnemonic: $mnemonics"
        echo "the wallet creation time: $creationtime"

        showcode() {
            whiptail --title "Write down your seed!" --msgbox "You have to backup your seed (mnemonic and creationtime):\
        \n\n$mnemonics\nCreation Time: $creationtime\n\nTake a sheet of paper, write the mnemonic and creationtime down!" 10 100
        }
        showcode
        while  ! (whiptail --title "Are you sure???" --yesno "Are you sure you did wrote down your mnemonic and creationtime?" 8 100) 
        do
            showcode
        done   

        getMnemonic() {
            mn=$(whiptail --inputbox "Please enter the mnemonic you wrote down before. (Format:  \"never,use,this,seed,never,use,this,seed,never,use,this,seed\")" 10 100 --title "Mnemonic check"  3>&1 1>&2 2>&3)
            echo $mn | sed 's/[[:space:]]//g' 
        }

        while [ "$mnemonics" != "$(getMnemonic)" ]
        do
            whiptail --msgbox "You entered the wrong mnemonic" 10 100 --title "Wrong mnemonic"
            showcode
        done

        getCreationTime() {
            ct=$(whiptail --inputbox "Please enter the creation time you wrote down before. (Format:  \"1504199300\")" 10 100 --title "CreationTime check"  3>&1 1>&2 2>&3)
            echo $ct | sed 's/[[:space:]]//g' 
        }

        while [ "$creationtime" != "$(getCreationTime)" ]
        do
            whiptail --msgbox "You entered the wrong creation time" 10 100 --title "Wrong creation time"
            showcode
        done    
    fi
    mvn -q clean package exec:java -Dexec.mainClass=iuno.tdm.paymentservice.init.WalletInitializer -Dexec.args="generate $mnemonics $creationtime"
fi

echo "Finished installing Payment Service"

echo "==================================="
echo "Install MixerControl"
echo "==================================="
cd /home/$mixer_user
git clone https://github.com/IUNO-TDM/MixerControl.git /home/$mixer_user/$mixer_control_folder
pip install socketIO-client-2 spidev
cd /home/$mixer_user/$mixer_control_folder
git reset --hard
git checkout $mixer_control_branch
git pull origin $mixer_control_branch
cp /home/$mixer_user/$mixer_installation_folder/private_config_production.js /home/$mixer_user/$mixer_control_folder/MixerControl-app/config/private_config_production.js
cp /home/$mixer_user/$mixer_installation_folder/private_config_testing.js /home/$mixer_user/$mixer_control_folder/MixerControl-app/config/private_config_testing.js


mixer_user_name=$(whiptail --inputbox "Please enter the client_id for this machine at the marketplace:" 8 100 --title "Configuring MixerControl" --nocancel 3>&1 1>&2 2>&3)
mixer_user_password=$(whiptail --inputbox "and now the client_secret for this machine at the marketplace:" 8 100 --title "Configuring MixerControl" --nocancel 3>&1 1>&2 2>&3)
mixer_retail_price=$(whiptail --inputbox "Enter the standard price for drinks at this machine:" 8 100 2 --title "Configuring MixerControl" --nocancel 3>&1 1>&2 2>&3)


echo s/replace_user_name/$mixer_user_name/g > myscript.sed
echo s/replace_user_password/$mixer_user_password/g >> myscript.sed
echo s/replace_retail_price/$mixer_retail_price/g >> myscript.sed

sed -f myscript.sed -i /home/$mixer_user/$mixer_control_folder/MixerControl-app/config/private_config_production.js
rm myscript.sed
cd /home/$mixer_user/$mixer_control_folder/MixerControl-app
npm install
npm install -g @angular/cli
npm run build

echo "Finished installing MixerControl"



echo "================================================"
echo "Installing PIGPIO - a dependency for PumpControl"
echo "================================================"

temp_folder=`mktemp -d -t iuno_temp_XXXXXXXX`
cd $temp_folder
wget abyz.co.uk/rpi/pigpio/pigpio.zip
unzip pigpio.zip
cd PIGPIO
make
sudo make install
sudo rm -r $temp_folder

echo "Finished installing PIGPIO"

echo "==================================="
echo "Install WIBU CodeMeter User Runtime"
echo "==================================="
temp_folder=`mktemp -d -t iuno_temp_XXXXXXXX`
cd $temp_folder
wget http://wibu.com/files/iuno/codemeter_6.60.2869.500_armhf.deb
sudo dpkg -i codemeter_6.60.2869.500_armhf.deb

sudo rm -r $temp_folder
echo "Finished installing WIBU Codemeter User Runtime"


echo "==================================="
echo "Install license manager"
echo "==================================="

cd /home/$mixer_user
mkdir -p $license_manager_folder
cp /home/$mixer_user/$mixer_installation_folder/LicenseManager /home/$mixer_user/$license_manager_folder
sudo chmod a+x /home/$mixer_user/$license_manager_folder/LicenseManager

echo "Finished installing LicenseManager"

echo "==================================="
echo "Install PumpControl"
echo "==================================="

cd /home/$mixer_user
mkdir -p $pump_control_folder
cp /home/$mixer_user/$mixer_installation_folder/PumpControl /home/$mixer_user/$pump_control_folder
cp /home/$mixer_user/$mixer_installation_folder/pumpcontrol.settings.conf /home/$mixer_user/pumpcontrol.settings.conf
cd /home/$mixer_user/$pump_control_folder

sudo chmod a+x PumpControl
sudo chown root PumpControl
sudo chgrp kmem PumpControl
sudo chmod ug+s PumpControl

echo "Finished installing PumpControl"

echo "==================================="
echo "Install Oracle Java 8 JDK"
echo "==================================="
java_version="$(java -version 2>&1)"
if [[  $java_version =~ 1.8.0_162 ]]
then
    echo "java version is up to date"
else
    temp_folder=`mktemp -d -t iuno_temp_XXXXXXXX`
    cd $temp_folder
    wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-arm32-vfp-hflt.tar.gz

    sudo mkdir -p /opt/jdk
    sudo tar -xzf jdk-8u162-linux-arm32-vfp-hflt.tar.gz -C /opt/jdk
    sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.8.0_162/bin/javac 400
    sudo update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.8.0_162/bin/java 400
    echo "Finished installing Oracle Java 8 JDK"
fi




echo "==================================="
echo "Initialize PM2"
echo "==================================="

cd /home/$mixer_user

cp /home/$mixer_user/$mixer_installation_folder/pm2_mixer.json /home/$mixer_user/pm2_mixer.json 
cp /home/$mixer_user/$mixer_installation_folder/start_env_production.sh /home/$mixer_user/start_env_production.sh
chmod a+x /home/$mixer_user/start_env_production.sh

echo "==================================="
echo "Patch /boot/config.txt for SPI1"
echo "==================================="

sudo bash /home/$mixer_user/$mixer_installation_folder/activateSPI1.sh

echo "*****************************************************************************"
echo "*A Reboot is required. Otherwise the PumpControl and Illumination wont work!*"
echo "*****************************************************************************"

echo "************************************"
echo "Installation finished. Start all by running script start_env_production"
echo "************************************"
