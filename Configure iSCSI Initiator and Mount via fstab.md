---
categories:
- Sysadmin
- How-To
date: 2023-08-10
lastmod: 2023-08-10
description: iSCSI boasts strong IO performance among many network storage sharing solutions. This article discusses how to configure an iSCSI initiator to discover and connect to a target, plus a little info regarding mkfs and fstab.
slug: configure-iscsi-initiator-and-mount-via-fstab
tags:
- iSCSI
- fstab
title: Configure iSCSI Initiator and Mount via fstab
---

## 0. Notes
- When writing this article, I ran the commands as root on Debian 11.

## 1. Configure iSCSI initiator
#### a. Install iSCSI initiator tools
```
# apt install -y open-iscsi
```

#### b. Discover the target
```
# iscsiadm -m discovery -t sendtargets -p 10.10.11.6:3260
10.10.11.6:3260,-1 iqn.iscsi.truenas.r510.vmdata1
```
This returns the IP and IQN addresses of the target. The useful bit is the IQN address.

#### c. (OPTIONAL) Discover the target using CHAP
> **If your target requires CHAP for discovery, then you need to follow this step instead of step b.**
```
# iscsiadm -m discovery -t sendtargets -p 10.10.11.6:3261
```
This of course would fail but it generates the corresponding sendtargets configuration file.

Edit `/etc/iscsi/send_targets/10.10.11.6,3261/st_config` to add/change the lines as follows:
```
discovery.sendtargets.auth.authmethod = CHAP
discovery.sendtargets.auth.username = example
discovery.sendtargets.auth.password = example_pwd
```

Then restart the `iscsid.service`:
```
# systemctl restart iscsid
```

Now use `discoverydb` mode with the `--discover` flag passed in to instruct `iscsiadm` to discover targets using the existing configurations.
```
# iscsiadm -m discoverydb -t sendtargets -p 10.10.11.6:3261 --discover
10.10.11.6:3261,-1 iqn.iscsi.truenas.r510.vmdata2
```

#### d. Configure CHAP authentication for the node
After the target is discovered, the configuration file of the corresponding node should have been generated.   
Edit `/etc/iscsi/nodes/iqn.iscsi.truenas.r510.vmdata1/10.10.11.6,3260` to add/change the lines as follows:
```
node.session.auth.authmethod = CHAP
node.session.auth.username = example
node.session.auth.password = example_pwd
```

Then restart the `iscsid.service`:
```
# systemctl restart iscsid
```

#### e. Connect to the target
```
# iscsiadm -m node -T iqn.iscsi.example.target1 --login
Logging in to [iface: default, target: iqn.iscsi.truenas.r510.vmdata1, portal: 10.10.11.6,3260]
Login to [iface: default, target: iqn.iscsi.truenas.r510.vmdata1, portal: 10.10.11.6,3260] successful.
```
```
# grep "Attached SCSI" /var/log/messages
Aug  7 09:58:18 owncloud kernel: [100867.993240] sd 3:0:0:0: [sdc] Attached SCSI disk
```
You should be able to also see it using `lsblk`:
```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda       8:0    0    1T  0 disk /mnt/owncloud_data_backup
sdb       8:16   0   40G  0 disk 
├─sdb1    8:17   0 39.9G  0 part /
├─sdb14   8:30   0    3M  0 part 
└─sdb15   8:31   0  124M  0 part /boot/efi
sdc       8:32   0    2T  0 disk 
sr0      11:0    1    4M  0 rom
```

---

## 2. Make a file system and mount it in `/etc/fstab`
#### a. Configure the iSCSI target to connect at system boot
Edit `/etc/iscsi/nodes/iqn.iscsi.truenas.r510.vmdata1/10.10.11.6,3260` to change the corresponding line as follows:
```
node.startup = automatic
```

#### b. Create a file system on the iSCSI disk
```
# mkfs.ext4 /dev/sdc
```

#### c. Edit `/etc/fstab` to mount the file system automatically at system boot
Get the UUID of the file system:
```
# blkid /dev/sdc
/dev/sdc: UUID="e7779e54-9242-4509-a7d6-c01746fc6161" BLOCK_SIZE="4096" TYPE="ext4"
```
Then add the following line to `/etc/fstab`:
```
UUID=e7779e54-9242-4509-a7d6-c01746fc6161 /mnt/owncloud_data ext4 rw,suid,_netdev,exec,auto,nouser,async 0 2
```
> The fourth field here is based on what the `defaults` parameter uses as specified in the manual page of `fstab`, with `dev` changed to `_netdev` to ensure the system won't try mounting the iSCSI disk until network is properly started.
To mount the file system immediately instead of waiting until next reboot:
```
# mount -a
```
It should be all good now:
```
# lsblk -f
NAME    FSTYPE  FSVER LABEL  UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                              
├─sda1  ext4    1.0          a2a6f036-bdc2-4175-828e-722caae22b10   33.9G     9% /
├─sda14                                                                          
└─sda15 vfat    FAT16        D9CD-8857                             113.1M     9% /boot/efi
sdb     ext4    1.0          94c1979f-4214-4f15-9305-af4a0d175e39  221.1G    73% /mnt/owncloud_data_backup
sdc     ext4    1.0          e7779e54-9242-4509-a7d6-c01746fc6161    1.9T     0% /mnt/owncloud_data
sr0     iso9660       cidata 2023-08-06-13-56-57-00
```

---

## 3. References:
[Red Hat documentation on iSCSI initiator](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/iscsi-api)

[Red Hat documentation on setting up CHAP for iSCSI connection](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/osm-setting-up-the-challenge-handshake-authentication-protocol)

[Franciscon Santos' answer in Unix & Linux StackExchange regarding the _netdev mounting parameter](https://unix.stackexchange.com/questions/195116/mount-iscsi-drive-at-boot-system-halts)
