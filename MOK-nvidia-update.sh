#!/bin/bash
#thanks to https://www.if-not-true-then-false.com/2025/debian-nvidia-guide/
#place here the most recent driver package version
#2026-07-14: 595.84
recent_version="595.84"

echo -e "MOK-signed Nvidia-Drivers Update Script by uk3k.de \n"
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo -e "Checking for local driver packages in current directory... \n"
localfile=$(ls | grep NVIDIA-Linux | tail -1)

if [ ! -z "$localfile" ]; then
  echo -e "found local driver package $localfile, what are we gonna do?"
  read -p 'use the (l)ocal file or (d)ownlod another one from nvidia.com? [l] ' mode  
  if [ "$mode" == "l" ] || [ -z "$mode" ]; then
    echo -e "using local file $localfile \n"
  fi
else
  echo -e "no local packages found ..."
fi

if [ "$mode" == "d" ] || [ -z "$localfile" ]; then
  echo -e ""
  echo -e "trying to download current driver from nvidia.com..."
  read -p 'Enter driver package version to download [e.g. 595.71.05 or 595.84]: ' version
  
  if [ -z "$version" ]; then
    echo -e "invalid version: {emtpy}; trying to download version $recent_version! \n"
    version=$recent_version
  fi
  
  arch=$(uname -m)
  rm NVIDIA-Linux-$arch-$version.run 2>/dev/null
  url="https://us.download.nvidia.com/XFree86/Linux-$arch/$version/NVIDIA-Linux-$arch-$version.run"
  echo -e "trying to fetch driver-version $version for $arch \n"
      
  if wget -q --spider "$url" > /dev/null; then
    wget $url
  else
    echo -e "404: Download @ $url not found; abort!"
    exit
  fi
  
  echo -e "Download complete, running installer \n"
  localfile=$(ls | grep NVIDIA-Linux | tail -1)
fi

read -p 'for Blackwell GPUs an newer (>=RTX5xxx) select MIT/GPL driver! [ENTER] to start installation... ' driver_package
chmod +x $localfile
./$localfile --module-signing-secret-key=/root/module-signing/MOK-nvidia.priv --module-signing-public-key=/root/module-signing/signing-nvidia.x509
echo -e ""
echo -e "local driver packages present: \n"
ls | grep NVIDIA-Linux
echo -e ""

if [ ! -z "$clean" ]; then
  rm NVIDIA-Linux-* 2>/dev/null
else
  exit
fi

echo -e "setting boot target to GUI (runlevel 5) \n"
systemctl set-default graphical.target
echo -e "reboot to finish update \n"
