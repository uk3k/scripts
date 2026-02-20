              
#!/bin/bash
#https://www.linuxtechi.com/how-to-install-kvm-on-debian/
#create bridge
#https://www.xmodulo.com/configure-linux-bridge-network-manager-ubuntu.html (GUI)
#https://www.cyberciti.biz/faq/how-to-add-network-bridge-with-nmcli-networkmanager-on-linux/ (CLI)
#convert vmware
#https://medium.com/@santoshgarole/migrating-virtual-machines-a-guide-to-migrating-vmware-vms-to-kvm-dd6860c52adc

#Hint: Use nm-connection-editor for creating the bridge  instead of the KDE provided applet, this seems to be unreliable

sudo apt update
sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager nm-connection-editor resolvconf-y
sudo virsh net-start default
sudo virsh net-autostart default
sudo modprobe vhost_net
echo "vhost_net" | sudo tee -a /etc/modules
sudo adduser $USER libvirt
sudo adduser $USER libvirt-qemu
newgrp libvirt
newgrp libvirt-qemu
read -p "check that network connections are NOT managed by /etc/interfaces!. [Enter --> got it]: "
nmcli connection show
read -p "DEVICE to be bridged?: " device
sudo nmcli con add ifname br0 type bridge con-name br0
sudo nmcli con add type bridge-slave ifname $device master br0
sudo nmcli con modify br0 bridge.stp no
ncli connection show
read -p "disable connection-NAME (of $device) before enbaling the bridge: " name
sudo nmcli con down "$name"
sudo nmcli con up br0
read -p "please reboot to finish setup [Enter --> got it]: "

