#!/bin/bash
config_file="/boot/config.txt"

reg_string="^\s*dtparam=spi=on"
replace_string="#dtparam=spi=on"

echo s/$reg_string/$replace_string/g > myscript.sed

spi1String="dtoverlay=spi1-2cs"

reg_string2="^\s*#\s*$spi1String"
replace_string2=$spi1String

echo s/$reg_string2/$replace_string2/g >> myscript.sed
sudo sed -f myscript.sed -i $config_file
rm myscript.sed

grep -qF "$spi1String" $config_file || sudo echo -e "\n$spi1String" >> $config_file

