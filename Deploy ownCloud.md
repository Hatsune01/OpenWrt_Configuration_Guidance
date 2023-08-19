---
categories:
- Sysadmin
- How-To
- Cloud Storage
- Homelab
date: 2022-12-20
lastmod: 2022-12-20
description: ownCloud is a very minimalistic cloud storage solution with great plugins like OnlyOffice and Impersonate.
slug: deploy-owncloud
tags:
- ownCloud
- Redis
- LAMP
title: Deploy ownCloud
---

## 0. Notes
- Apache is recommended for ownCloud, since ownCloud uses a lot of PHP and Apache is good at this.

- I'm not very sure about the PHP OPcache configurations. The ownCloud docs say nothing has to be configured for OPcache in PHP 7, but the `php.ini` file has all configs related to OPcache commented out by default. I'll give the ownCloud docs benefit of doubt. [See this.](https://doc.owncloud.com/server/10.11/admin_manual/configuration/server/caching_configuration.html#opcache-configuration)

- I used Debian 11 when writing this.

- **RUN AS ROOT !!!!!!!!**

---

## 1. Install a LAMP stack

#### a. Install Apache and MariaDB

```shell
apt update -y && apt upgrade
apt install -y apache2 mariadb-server
```

#### b. Install PHP and its required modules

```shell
apt install -y php libapache2-mod-php php-{curl,gd,intl,json,mbstring,xml,zip,mysql,ssh2,imap,ldap,bz2,imagick,gmp,pear,dev}
```
> Use `php -m` to check installed PHP modules.

- Use `pecl` to install `smbclient` and `mcrypt` modules for PHP.
```shell
apt install -y libsmbclient-dev libmcrypt-dev  # Install dependencies.
pecl install smbclient smbclient
```
```shell
# Edit php.ini.
cd /etc/php/7.4/cli
cp php.ini php.ini.bak  # Back up the file first.
vim php.ini
```
```ini
; Add the following directives below line 937.
extension=smbclient.so
extension=mcrypt.so
```

---

## 2. Configure MariaDB

```shell
mariadb_secure_installation
# Usually mysql_secure_installtion should work, but it sometimes doesn't.
```

```sql
create database ownclouddb;
grant all on ownclouddb.* to 'owncloud'@'localhost' identified by 'owncloudpwd';
flush privileges;
exit;
```

```shell
# Log into MariaDB as the new user to check if it's been successfully created.
mysql -u owncloud -p
```

---

## 3. Configure Apache

```shell
# Enable required Apache modules
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod unique_id

systemctl restart apache2
```

```shell
touch /etc/apache2/sites-available/owncloud.conf
```

owncloud.conf
```apacheconf
<VirtualHost *:80>
  ServerName example.net
  DocumentRoot /var/www/owncloud

  <Directory /var/www/owncloud/>
    Options +FollowSymlinks
    AllowOverride All 

    <IfModule mod_dav.c>
      Dav off 
    </IfModule>
    # Apache DAV module is disabled, since ownCloud has its built-in WebDAV server.
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

```shell
a2ensite owncloud.conf
systemctl reload apache2
```

> Useful Apache commands:  
> `apachectl -t` Check Apache configurations  
> `apachectl -S` Check Apache virtual host configurations 

---

## 4. Install ownCloud binaries

#### a. Download ownCloud package and verify it

```shell
wget https://download.owncloud.com/server/stable/owncloud-complete-latest.tar.bz2
wget https://download.owncloud.com/server/stable/owncloud-complete-latest.tar.bz2.sha256
sha256sum -c owncloud-complete-latest.tar.bz2.sha256 < owncloud-complete-latest.tar.bz2
```

#### b. Create `owncloud_data` directory

```shell
mkdir /mnt/owncloud_data
```
> - Create the directory in a different location other than the ownCloud document root.
> - The best practice would be to mount `owncloud_data` on an external drive.
> - The installer script will then use symbolic links to point to the directories inside `owncloud_data`. This would be very handy when upgrading the ownCloud instance, since the data directory could grow very large and manually transferring the directories after upgrading can be very time-consuming.

#### c. Use the scripts to install the binary

```shell
touch instance.sh owncloud_prep.sh
# Name instance.sh whatever you want.
# DO NOT change the name of owncloud_prep.sh.
chmod u+x instance.sh owncloud_prep.sh
./instance.sh
```
> - For the details of the scripts, check out the appendix.
> - Remember to change the variables in `instance.sh` according to your settings.

Now visit the ownCloud instance and finalise the installation.
Remember to run `instance.sh` **AGAIN** to secure `.htaccess` file after you've done the finalisation. Otherwise, your files can be directly accessed by appending the file path to the URL of the ownCloud instance.

---

## 5. Configure PHP caching & file locking

- On a **SEPARATE** server, install and set up Redis (distributed environments).
```shell
apt install -y redis-server
cp redis.conf redis.conf.bak
vim redis.conf
```

- Add the following lines into `/etc/redis/redis.conf`.
```
maxmemory 3gb
maxmemory-policy volatile-ttl
bind 127.0.0.1 10.10.11.71
requirepass ReallyLongAndRandomPassword
```

```shell
systemctl restart redis-server
```

> I used Redis version 6 when writing this, where ACL authentication was introduced, which as per ownCloud docs, is not supported by ownCloud. However, the `requirepass` directive offers a sort of compatibility layer on top of ACL, which in my case, allowed Redis 6 to work quite well with ownCloud. **KEEP AN EYE ON ANY FUTURE CHANGES!!!** [See this.](https://doc.owncloud.com/server/10.11/admin_manual/configuration/server/caching_configuration.html#redis)

- On the **OWNCLOUD SERVER**, install PHP modules for APCu and Redis.
```shell
apt install -y php-apcu
apt install -y php-redis
```

- Add the following lines into `config.php`.
```php
# Caching & file locking configurations
'filelocking.enabled' => true,
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\APCu',
'redis' => [
  'host' => '10.10.11.71',
  'port' => 6379,
  'timeout' => 0,
  'password' => 'ReallyLongAndRandomPassword',
  'dbindex' => 0,
]
```

```shell
systemctl restart apache2
```

> Use the `monitor` command in `redis-cli` to monitor activities in Redis, which could help determine if ownCloud is working well with Redis or not.

---

## 6. Preview generation

```shell
# Install ffmpeg to generate video previews.
apt install -y ffmpeg
```

---

## 7. A couple more things to do

#### a. Manage trusted domains in config.php

Doing so allows access from the specified addresses.

> The file is located in ownCloud document root. By default, it is `/var/www/owncloud/config/config.php`.

```php
  'trusted_domains' =>
  array (
    0 => '10.10.11.89',
    1 => 'example.net',
  ),
```

#### b. Configure Cron jobs

This calls the `occ` program every 15 min .
```shell
crontab -u www-data -e
# This means editing www-data's crontab.
# Add the following line:
*/15 * * * * /usr/bin/php -f /var/www/owncloud/occ system:cron

# Verify if the cron job has been added.
crontab -u www-data -l
```

> Remember to change the Cron option from AJAX to Cron in Settings -> General (in Admin section) -> Cron.

References: [Cron job configurations](https://doc.owncloud.com/server/next/admin_manual/configuration/server/background_jobs_configuration.html#cron)


#### c. Enable SSL

- [[Enable HTTPS for Apache]]
- Add the following line to the `<VirtualHost *:80>` entry to redirect all HTTP traffic to HTTPS:
```apacheconf
Redirect permanent / https://example.com/
```

- Add the following line to the `<VirtualHost *:443>` entry to enable the HTTP Strict Transport Security header:
```apacheconf
<IfModule mod_headers.c>
  Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
</IfModule>
```

---

## References
[Detailed installation guide. Very useful. It serves as a starting point and a workflow guidance.](https://doc.owncloud.com/server/next/admin_manual/installation/manual_installation/manual_installation.html)

[Installation prerequisites, e.g. PHP modules](https://doc.owncloud.com/server/next/admin_manual/installation/manual_installation/manual_installation_prerequisites.html)

[Apache configurations](https://doc.owncloud.com/server/next/admin_manual/installation/manual_installation/manual_installation_apache.html)

[Database configurations](https://doc.owncloud.com/server/next/admin_manual/configuration/database/linux_database_configuration.html#mysql-mariadb)

[ownCloud official installer scripts](https://doc.owncloud.com/server/next/admin_manual/installation/manual_installation/script_guided_install.html)

[Caching configurations](https://doc.owncloud.com/server/10.10/admin_manual/configuration/server/caching_configuration.html)

[Manage trusted domains](https://doc.owncloud.com/server/10.10/admin_manual/maintenance/migrating.html#managing-trusted-domains)

[Hardening and security guidance](https://doc.owncloud.com/server/10.10/admin_manual/configuration/server/harden_server.html)

[Preview generation](https://doc.owncloud.com/server/next/admin_manual/configuration/files/previews_configuration.html)

---

## Appendix
#### instance.sh
```shell
#!/bin/bash
# Script Version 2022.06.23

# This script prepares the parameters for owncloud_prep.sh
# Handy if you have more instances to maintain where the process stays the same with different parameters
# The processing script is expected in the same directory of this script.

# To setup this script for your environment, adopt the following variables to your needs:
#
# ocname        the name of your directory containing the owncloud files
# ocroot        the path to ocname, usually /var/www (no trailing slash)
# linkroot      the path to your source directory for linking data and apps-external (no trailing slash)
# htuser        the webserver user
# htgroup       the webserver group
# rootuser      the root user

ocname='owncloud'
ocroot='/var/www'

linkroot='/mnt/owncloud_data'

htuser='www-data'
htgroup='www-data'
rootuser='root'

if [ "$(id -u)" != 0 ]; then
  printf "\nThis script should be run as root user to allow filesystem modifications\nExiting\n\n"
fi

printf "\nConsider backing up the database before you continue when upgrading!\n\n"

# Resolve the absolute path this script is located and expects the called script to be there too
DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

$DIR/owncloud_prep.sh "$ocname" "$ocroot" "$linkroot" "$htuser" "$htgroup" "$rootuser"
```

---

#### owncloud_prep.sh
```shell
#!/bin/bash
# Script Version 2022.06.23

# To set up this script for your environment, hand over the following variables according your needs:
#
# ocname        the name of your directory containing the owncloud files
# ocroot        the path to ocname, usually /var/www (no trailing slash)
# linkroot      the path to your source directory for linking data and apps-external (no trailing slash)
# htuser        the webserver user
# htgroup       the webserver group
# rootuser      the root user

# Short description for parameters used in find
#
# -L       ... Follow symbolic links. Needed in case if links are used or present
# -path    ... The path to process
# -prune   ... If the file is a directory, do not descend into it (used to exclude directories)
# -o       ... OR (to add more parameters)
# -type    ... File is of type [d ... directory, f ... file]
# -print0  ... Print the full file name on the standard output, followed by a null character
# xargs -0 ... Reads items from the standard input, input items are terminated by a null character


ocname=$1
ocroot=$2
ocpath=$ocroot/$ocname
ocdata=$ocroot/$ocname/'data'
ocapps_external=$ocpath/'apps-external'
oldocpath=$ocroot/$ocname'_'$(date +%F-%H.%M.%S)

linkroot=$3
linkdata=$linkroot/'data'
linkapps_external=$linkroot/'apps-external'

htuser=$4
htgroup=$5
rootuser=$6

arguments=6

filmod="0640"
dirmod="0750"
htamod="0640"

# Because the data directory can be huge or on external storage, an automatic chmod/chown can take a while.
# Therefore this directory can be treated differently.
# If you have already created an external "data" and "apps-external" directory which you want to link,
# set the paths above accordingly. This script can link and set the proper rights and permissions
# depending what you enter when running the script.

# When the instance is setup either post a fresh install or after an upgrade, run this script again but
# only for securing ".htaccess files". This sets the appropriate ownership and permission for them.

# In case you upgrade an existing installation, your original directory will be renamed including a timestamp


if [ "$#" -ne "$arguments" ]; then
  printf "\nThis script needs $arguments arguments, $# given.\n\n"
fi

printf "\nFollowing parameters used\n\n"
printf "ocname: $ocname\nocroot: $ocroot\nlinkroot: $linkroot\nhtuser: $htuser\nhtgroup:  $htgroup\nrootuser:  $rootuser\n"

function get_tar {
  read -p "Please specify the tar file to extract with full path: " -r -e tarFile
  if [ ! -f "$tarFile" ]; then
    echo "tar file to extract not found. Exiting."
    echo
    exit
  fi
}

echo

read -p "Do you want to secure your .htaccess files post installing/upgrade (y/N)? " -r -e answer
(echo "$answer" | grep -iq "^y") && do_secure="y" || do_secure="n"

if [ "$do_secure" = "y" ]; then
  printf "\nSecuring .htaccess files with chmod/chown\n"
  if [ -f ${ocpath}/.htaccess ]; then
    chmod $htamod ${ocpath}/.htaccess
    chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
  fi
  if [ -f ${ocdata}/.htaccess ];then
    chmod $htamod ${ocdata}/.htaccess
    chown ${rootuser}:${htgroup} ${ocdata}/.htaccess
  fi
  printf "\nDone\n\n"
  exit
fi


read -p "Do you want to install a new instance (y/N)? " -r -e answer
(echo "$answer" | grep -iq "^y") && do_new="y" || do_new="n"


if [ "$do_new" = "n" ]; then
    read -p "Do you want to upgrade an existing installation (y/N)? " -r -e answer
    (echo "$answer" | grep -iq "^y") && do_upgrade="y" || do_upgrade="n"
fi

read -p "Use links for data and apps-external directories (Y/n)? " -r -e answer
(echo "$answer" | grep -iq "^n") && uselinks="n" || uselinks="y"

if [ "$uselinks" = "y" ]; then
  read -p "Do you want to chmod/chown these links (y/N)? " -r -e answer
  (echo "$answer" | grep -iq "^y") && chmdir="y" || chmdir="n"
fi

# check if upgrading an existing installation
if [ "$do_upgrade" = "y" ]; then
  read -p "Is the instance in maintenance mode? (y/N)? " -r -e answer
  (echo "$answer" | grep -iq "^y") && mmode="y" || mmode="n"
  if [ "$mmode" = "n" ]; then
    echo "Please enable maintenance mode first: sudo -u$htuser ./occ maintenance:mode --on"
    echo
    exit
  fi
  get_tar
  # rename the source for backup reasons
  if [ -d ${ocpath} ]; then
    mv $ocpath $oldocpath
  fi
fi

# get the tar file for new installs
if [ "$do_new" = "y" ]; then
  get_tar
fi

# in case of upgrade or new, extract the source
if [ "$do_upgrade" = "y" ] || [ "$do_new" = "y" ]; then
  mkdir -p $ocpath
  tar xvf "$tarFile" -C $ocpath --strip-components=1

  if [ $? != 0 ]; then
    echo
    echo "tar extract failed, please check !"
    echo
    # rename back in case of tar errors
    if [ "$do_upgrade" = "y" ] && [ -d ${oldocpath} ]; then
      rm -r $ocpath
      mv $oldocpath $ocpath
    fi
    exit
  fi
fi

# create / link missing directories
printf "\nCreating or linking possible missing directories \n"
mkdir -p $ocpath/updater
# check if directory creation is possible and create if ok
if [ "$uselinks" = "n" ]; then
  if [ -L ${ocdata} ]; then
    echo "Symlink for $ocdata found but mkdir requested. Exiting."
    echo
    exit
  else
    echo "mkdir $ocdata"
    echo
    mkdir -p $ocdata
  fi
  if [ -L ${ocapps_external} ]; then
    echo "Symlink for $ocapps_external found but mkdir requested. Exiting."
    echo
    exit
  else
    printf "mkdir $ocapps_external \n"
    mkdir -p $ocapps_external
  fi
else
  if [ -d ${ocdata} ] && [ ! -L $ocdata ]; then
    echo "Directory for $ocdata found but link requested. Exiting."
    echo
    exit
  else
    printf "ln $ocdata --> $linkdata\n"
    mkdir -p $linkdata
    ln -sfn $linkdata $ocdata
  fi
  if [ -d ${ocapps_external} ] && [ ! -L $ocapps_external ]; then
    echo "Directory for $ocapps_external found but link requested. Exiting."
    echo
    exit
  else
    printf "ln $ocapps_external --> $linkapps_external\n"
    mkdir -p $linkapps_external
    ln -sfn $linkapps_external $ocapps_external
  fi
fi

# copy existing *config.php and all .json files which are required for the new webUI
if [ "$do_upgrade" = "y" ]; then
  # check if at minimum a config.php file is present
  # note that you can have more than one config.php representing different settings
  if [ -f ${oldocpath}/config/config.php ]; then
    printf "\nCopy existing *config.php and *.json files \n"
    # using find to omit messages if no files found
    find ${oldocpath}/config/ -name \*config.php -exec cp {} ${ocpath}/config/ \;
    find ${oldocpath}/config/ -name \*.json -exec cp {} ${ocpath}/config/ \;
  else
    printf "Skip to copy old config.php, file not found: ${oldocpath}/config/config.php \n"
  fi
fi

printf "\nchmod files and directories excluding data and apps-external directory\n"

# check if there are files to chmod/chown available. If not, exiting.
# chmod
if [ ! "$(find $ocpath -maxdepth 1 -type f)" ]; then
  echo "Something is wrong. There are no files to chmod. Exiting."
  exit
fi

find -L ${ocpath} -path ${ocdata} -prune -o -path ${ocapps_external} -prune -o -type f -print0 | xargs -0 chmod $filmod
find -L ${ocpath} -path ${ocdata} -prune -o -path ${ocapps_external} -prune -o -type d -print0 | xargs -0 chmod $dirmod

# no error messages on empty directories
if [ "$chmdir" = "n" ] && [ "$uselinks" = "n" ]; then

  printf "chmod data and apps-external directory (mkdir) \n"

  if [ -n "$(ls -A $ocdata)" ]; then
    find ${ocdata}/ -type f -print0 | xargs -0 chmod $filemod
  fi
  find ${ocdata}/ -type d -print0 | xargs -0 chmod $dirmod
  if [ -n "$(ls -A $ocapps_external)" ]; then
    find ${ocapps_external}/ -type f -print0 | xargs -0 chmod $filemod
  fi
  find ${ocapps_external}/ -type d -print0 | xargs -0 chmod $dirmod
fi

if [ "$chmdir" = "y" ] && [ "$uselinks" = "y" ]; then

  printf "chmod data and apps-external directory (linked) \n"

  if [ -n "$(ls -A $ocdata)" ]; then
    find -L ${ocdata}/ -type f -print0 | xargs -0 chmod $filmod
  fi
  find -L ${ocdata}/ -type d -print0 | xargs -0 chmod $dirmod
  if [ -n "$(ls -A $ocapps_external)" ]; then
    find -L ${ocapps_external}/ -type f -print0 | xargs -0 chmod $filmod
  fi
  find -L ${ocapps_external}/ -type d -print0 | xargs -0 chmod $dirmod
fi

#chown
printf "chown files and directories excluding data and apps-external directory \n"

find  -L $ocpath  -path ${ocdata} -prune -o -path ${ocapps_external} -prune -o -type d -print0 | xargs -0 chown ${rootuser}:${htgroup}
find  -L $ocpath  -path ${ocdata} -prune -o -path ${ocapps_external} -prune -o -type f -print0 | xargs -0 chown ${rootuser}:${htgroup}

# do only if directories are present
if [ -d ${ocpath}/apps/ ]; then
  printf "chown apps directory \n"
  chown -R ${htuser}:${htgroup} ${ocpath}/apps/
fi
if [ -d ${ocpath}/config/ ]; then
  printf "chown config directory \n"
  chown -R ${htuser}:${htgroup} ${ocpath}/config/
fi
if [ -d ${ocpath}/updater/ ]; then
  printf "chown updater directory \n"
  chown -R ${htuser}:${htgroup} ${ocpath}/updater
fi

if [ "$chmdir" = "n" ] && [ "$uselinks" = "n" ]; then
  printf "chown data and apps-external directories (mkdir) \n"
  chown -R ${htuser}:${htgroup} ${ocapps_external}/
  chown -R ${htuser}:${htgroup} ${ocdata}/
fi
if [ "$chmdir" = "y" ] && [ "$uselinks" = "y" ]; then
  printf "chown data and apps-external directories (linked) \n"
  chown -R ${htuser}:${htgroup} ${ocapps_external}/
  chown -R ${htuser}:${htgroup} ${ocdata}/
fi

printf "\nchmod occ command to make it executable \n"
if [ -f ${ocpath}/occ ]; then
  chmod +x ${ocpath}/occ
fi


# tell to remove the old instance, do upgrade and end maintenance mode etc.
printf "\nSUCCESS\n\n"
if [ "$do_upgrade" = "y" ]; then
  if [ "$uselinks" = "n" ]; then
    echo "Please migrate (move/copy) your data/ and apps-external/ directory manually back to the original location BEFORE running the upgrade command!"
    echo
  fi
  echo "Please change to your upgraded ownCloud directory: cd $ocroot/$ocname"
  echo "Please manually run: sudo -u$htuser ./occ upgrade"
  echo "Copy any changes manually added in .user.ini and .htaccess from the backup directory"
  echo "Please manually run: sudo -u$htuser ./occ maintenance:mode --off"
  echo "Please manually remove the directory of the old instance: $oldocpath"
  echo "When successfully done, re-run this script to secure your .htaccess files"
  echo
fi

if [ "$do_new" = "y" ]; then
  echo "Open your browser, configure your instance and rerun this script to secure your .htaccess files"
  echo
fi
```
