#!/bin/bash
#creates a custom ubuntu iso

##userinput
echo "this will create a bootable custom image of ubuntu"
read -p "Volume-Name: " volume
read -p "File-Name (*.iso): " output
read -p "Source dir(folder containing extracted and modified iso-files): " -i "" -e source

##create iso
dpkg -p genisoimage > /dev/null 2>&1
if [ $? != 0 ]; then
   sudo apt-get update && sudo apt-get install genisoimage -y
else
   sudo genisoimage -r -V "$volume" -cache-inodes -J -l -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $output.iso $source/
fi

echo "done!"

