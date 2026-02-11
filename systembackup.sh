
#!/bin/bash
#advanced script for backup 2025-10-21
#compress backup
#tar cvpzf /media/Backup/$(date +%F_%H-%M-%S)_Homeserver-FileBackup.tgz --exclude=/$(date +%F_%H-%M-%S)_Homeserver-FileBackup.tgz --exclude=/proc --exclude=/lost+found --exclude=/sys --exclude=/mnt --exclude=/tmp --exclude=/run  --exclude=/var/log --exclude=/media --exclude=/boot --exclude=/var/lib/systemd/coredump --warning=no-file-ignored /
#decompress backup
#tar xvpfz backup.tgz -C /

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
else
        read -p 'Backup [f]iles or do a full [d]isk dump? ' select
        read -p '[Vaccum] journal logs? (enter "skip" to skip) ' clean
fi

if [ -z "$clean" ]; then
        echo  "vacuuming journactl ..."
        journalctl --flush --rotate --vacuum-time=1s
        journalctl --user --flush --rotate --vacuum-time=1s
        echo ""
else
        echo "skipped vacuuiming journalctl ..."
fi

if [ -z "$select" ]; then
        echo "Error: No backup strategy selected, aborting ..."
        exit 1
fi

if [ "$select" == "f" ]; then
        echo "Starting Files backup: Checking for Backup-Drive...)"
        echo "..."
        backup_mnt=$(findmnt /media/Backup | grep / | awk '{print $2}')
        if [ -z $backup_mnt ]; then
                echo "Trying to auto-mount backup-drive ..."
                mount /media/Backup
                echo "Checking again for backup-drive ..."
                backup_mnt=$(findmnt /media/Backup | grep / | awk '{print $2}')
                if [ -z $backup_mnt ]; then
                        echo "Error: Backup drive not mounted"
                        exit 1
                fi
        fi
        echo "Backup drive is mounted on: $backup_mnt"
        echo ""
        df $backup_mnt -h
        echo ""
        echo ""
        echo "If correct press enter, ctrl+c to abort"
        read input
        echo "Backing up system files ..."
        tar cvpzf /media/Backup/$(date +%F_%H-%M-%S)_Homeserver-FileBackup.tgz --exclude=/$(date +%F_%H-%M-%S)_Homeserver-FileBackup.tgz --exclude=/proc --exclude=/lost+found --exclude=/sys --exclude=/mnt --exclude=/tmp --exclude=/run  --exclude=/var/log --exclude=/media --exclude=/boot --exclude=/var/lib/systemd/coredump --warning=no-file-ignored /home/uk3k
        echo "Backup finished, syncing discs..."
        sync
        echo "Trying to unmount and power-off backup-drive ..."
        dev=$(findmnt /media/Backup | grep / | awk '{print substr($2, 6, length($2)-6)}')
        echo "Debug device name: $dev"
        busy=$(awk "{ print \$9 }"  /sys/block/$dev/stat)
        echo "Debug disk state: $busy"
        while [ $busy != "0" ]; do
                echo "backup device syncing, waiting for disk idle (0): $busy"
        done
        umount /media/Backup
        udisksctl power-off -b "/dev/"$dev
        echo ""
        echo "done!"
        exit 1
fi

if [ "$select" == "d" ]; then
        echo "Trying to auto-mount backup-drive ..."
        mount /media/Backup
        echo "Starting Full System backup (Disk Dump): Reading disks..."
        echo "..."
        root_path=$(findmnt / | grep / | awk '{print $2}')
        backup_mnt=$(findmnt /media/Backup | grep / | awk '{print $2}')
        ddif=$(findmnt / | grep / | awk '{print substr($2, 1, length($2)-1)}')
        if [ -z $root_path ]; then
                        echo "Error: root filesystem not found"
                        exit 1
        fi
        if [ -z $backup_mnt ]; then
                echo "Trying to auto-mount backup-drive ..."
                mount /media/Backup
                echo "Checking again for backup-drive ..."
                backup_mnt=$(findmnt /media/Backup | grep / | awk '{print $2}')
                if [ -z $backup_mnt ]; then
                        echo "Error: Backup drive not mounted"
                        exit 1
                fi
        fi
        echo "Root filesystem found on: $root_path"
        echo "Backup drive is mounted on: $backup_mnt"
        echo ""
        df $root_path $backup_mnt -h
        echo ""
        echo ""
        echo "If correct press enter, ctrl+c to abort"
        read input
        echo "Backing up filesystem $ddif ..."
        dd if=$ddif bs=64K | pv | pigz > /media/Backup/$(date +%F_%H-%M-%S)_Homeserver-FullBackup.img.gz
        echo "Backup finished, syncing discs..."
        sync
        echo "Trying to unmount and power-off backup-drive ..."
        dev=$(findmnt /media/Backup | grep / | awk '{print substr($2, 6, length($2)-6)}')
        echo "Debug device name: $dev"
        busy=$(awk "{ print \$9 }"  /sys/block/$dev/stat)
        echo "Debug disk state: $busy"
        while [ $busy != "0" ]; do
                echo "backup device syncing, waiting for disk idle (0): $busy"
        done
        umount /media/Backup
        udisksctl power-off -b "/dev/"$dev
        echo ""
        echo "done!"
        exit 1
fi

echo "Error: No valid input ('f' or 'd') given!"
