#!/bin/bash
#thanks to https://www.if-not-true-then-false.com/2025/debian-nvidia-guide/
echo "MOK-signed Nvidia-Drivers Update Script by uk3k.de"
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
else
  echo "trying to download current driver automatically..."
  read -p 'whats the current nvidia driver version? [e.g. 580.126.09]: ' version
fi
if [ -z $version ]
  then echo "invalid version: {emtpy}; abort!"
  exit
else
  arch=$(uname -m)
  url="https://us.download.nvidia.com/XFree86/Linux-$arch/$version/NVIDIA-Linux-$arch-$version.run"
  echo "trying to fetch driver-version $version for $arch"
  echo "deleting old files..."
  rm NVIDIA-Linux-* 2>/dev/null
fi
if wget -q --spider "$url" > /dev/null; then
  wget $url
else
  echo "404: Download @ $url not found; abort!"
  exit
fi
echo "Download complete, running installer"
chmod +x NVIDIA-Linux-$arch-$version.run
  ./NVIDIA-Linux-$arch-$version.run --module-signing-secret-key=/root/module-signing/MOK-nvidia.priv --module-signing-public-key=/root/module-signing/signing-nvidia.x509
read -p 'finished, cleanup installer files? (input "keep" to keep downloaded files): ' keep
if [ -z $keep ]; then
  rm NVIDIA-Linux-* 2>/dev/null
else
  exit
fi
echo "setting boot target to GUI (runlevel 5)"
systemctl set-default graphical.target
echo "reboot to finish update"
