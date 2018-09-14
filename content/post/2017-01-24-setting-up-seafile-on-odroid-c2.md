---
title: Setting up Seafile on an Odroid C2
date: "2017-01-24"
---

# Steps

This post describes the steps required to set up a self-hosted [Seafile](https://www.seafile.com/en/home/) server (a Dropbox alternative) using an Odroid C2 with external hard-drive and a custom domain with HTTPs. If not mentioned otherwise, many command should be run as `root` user.

## Hardware

- [Odroid C2 Starter kit](http://www.pollin.de/shop/dt/ODY0OTgxOTk-/Bauelemente_Bauteile/Entwicklerboards/Odroid/ODROID_C2_Set_mit_8_GB_eMMC_Modul_Gehaeuse_und_Netzteil.html) with: Odroid C2, eMMC module with Ubuntu 16.04, power adapter, case, external hard drive

## Basic OS setup

Install all updates

```shell
apt-get update
apt-get dist-upgrade
apt-get autoremove
apt-get install screen vim-nox
```

Remove all unnecessary packages, e. g. the graphical desktop, if installed. I suggest running all administrative tasks inside a GNU screen session so that any terminated network connection does not kill the running process(es).

## User accounts

Create a dedicated user account for administrative tasks in case you do not want do use the pre-created `odroid` account (because it may be easier to guess):

```shell
adduser admin
usermod -aG admin
```

On Ubuntu the `admin` group is part of the `sudoers` file automatically, so adding the new user to this group make the account sudo-able.

Remove pre-existing user account after having verified that the new user account is able to log in and perform administrative tasks.

```shell
userdel -r odroid
```

Add a dedicated user account for the Seafile server which is non-privileged:

```shell
adduser seafile
```

## Change hosname

Edit hostname to something sensible (defaults to `odroid64`) with the preinstalled image:

```shell
vim /etc/hostname
hostname seafile
```

Eventually it may make sense to reboot at this point or restart the networking, so that any routers which this device is attached to pick up the new hostname and makes it available for routing.

## Set up login with SSH keys

On your remote client (from which you are connecting via SSH to the Odroid), make SSH keys (if you do not already have some) and make them available on the seafile server:

```shell
ssh-keygen
ssh-copy-id admin@seafile
# accept host key once
# provide password once
ssh admin@seafile
# to verify that the login works
```

## Set up unattended upgrade

In order to get security upgrades automatically and non-interactively we set up Ubuntu's `unattended-upgrades`:

```shell
sudo apt-get install unattended-upgrades

# Uncomment the security updates at the beginning of this file:
vim /etc/apt/apt.conf.d/50unattended-upgrades

// Automatically upgrade packages from these (origin:archive) pairs
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
//      "${distro_id}:${distro_codename}-updates";
//      "${distro_id}:${distro_codename}-proposed";
//      "${distro_id}:${distro_codename}-backports";
};

// ...
```

## Additional packages required later

```shell
sudo apt-get install fail2ban ufw
```

## External data directory

I am using an external hard-disk drive attached via USB. Find out its partition name:

```shell
dmesg | grep sda
```

Create a proper file system, because it was formatted as NTFS before:

```shell
cfdisk /dev/sda
# remove all partitions
# add single primary partition with type Linux
# write & quit
```

Create filesystem

```shell
mke2fs -t ext4 /dev/sda1
```

Find out UUID for `fstab`

```shell
blkid /dev/sda1
```

Add new mount point for external hard drive

```shell
mkdir /media/ext_hd
```

Add new filesystem to `/etc/fstab`:

```shell
vim /etc/fstab
UUID=<UUID from blkid> /media/ext_hd/  ext4  user,auto,errors=remount-ro,noatime 0 0
```

## Setting up Seafile

Follow the [setup instructions in the manual](https://manual.seafile.com/deploy/using_sqlite.html).

For the Odroid C2 you need the [RaspberryPi package](https://github.com/haiwen/seafile-rpi/releases), since it is compiled for `armhf` architecture. Since the Odroid is `aarch64` instead (which is compatible) the following steps are also required:

```shell
dpkg --add-architecture armhf
apt-get update
apt-get install aptitude
# Reason to use aptitude described at https://forum.seafile.com/t/seafile-server-on-arm64-aarch64-working/1405/3
aptitude install libc6:armhf libselinux1:armhf

# Other dependencies:
aptitude -y install python2.7 python-setuptools python-simplejson python-imaging sqlite3
```

Seafile requires an `armhf`-compatible libc and libselinux to be installed or it may show errors when running the setup script later on.

Also, I will be using SQLite as DB, because I intend to run this server only for a couple of users, but YMMV.

Setting up Seafile is as easy as running the corresponding setup script after having extracted the package file.

```shell
# As user seafile (!)
cd /home/seafile
wget <download url>
tar xfz package.tar.gz
ln -s seafile-server-<version> seafile-server-latest
cd seafile-server-latest
./setup-seafile.sh

# answer the given questions and you're done
```

After having started the Seafile server for the first time, open it up in your browser and create an administrative account. This first user will be allowed to create new user accounts, so it is quite important. In addition, on the setup-page you can also define the external data storage location and an external database, if desired.


## Apache

I suggest [running Seafile behind Apache web server](https://manual.seafile.com/deploy/deploy_with_apache.html) (or [Nginx](https://manual.seafile.com/deploy/deploy_with_nginx.html), if you prefer), since it allows us to close all other firewall ports and only leave HTTP (443) open later on.

## Apache HTTPS

I strongly advise to enable HTTPS on your Apache server so that any login passwords are not sent in plain text across the nextwork. The [manual contains full instructions for this](https://manual.seafile.com/deploy/https_with_apache.html) and it is not much work to set up self-signed certificates.

## Firewall

Before exposing this machine to the (evil) internet, we set up some sensible firewall rules using `ufw` (installed above):

```shell
ufw allow "Apache Secure"
ufw allow from 192.168.0.0/16 to any app OpenSSH
ufw default deny incoming
ufw default allow outgoing

ufw logging on

ufw enable
ufw status verbose
```

When using app names ("Apache Secure") please make sure that these names are known to your installation by checking them with `ufw app list`.

## Domain and port-forwarding

I am using a personal subdomain for my seafile server, so please add your DNS entries accordingly. As soon as the DNS entries are available you may want to expose the HTTPS port 443 to the world by port-forwarding it in your router.
## Signed HTTPS certificate

Getting a signed HTTPS certificate for your Apache web server can be accomplished by installing and running the [Let's Encrypt](http://letsencrypt.com/) client. Descriptions for a variety of operating system / server software combinations [is available here](https://certbot.eff.org/), I have been using the instructions for [Apache on Ubuntu 126.04](https://certbot.eff.org/#ubuntuxenial-apache):

    apt-get install python-letsencrypt-apache
    letsencrypt --apache

The script asks for a couple of details, but if you have set up your Apache with a self-signed certificate, available at an external domain already, it should be able to figure out most of it all by itself.

Since their certificates are valid for three month periods only, they recommend setting up a cronjob which automatically renews the certificates if they are expiring:

```shell
crontab -e
# edit / add these lines

SHELL=/bin/bash
# Attempt to automatically renew expiring SSL certificates twice a day
0 1 * * * /usr/bin/letsencrypt renew -q
0 13 * * * /usr/bin/letsencrypt renew -q
```

## Logroration

The official docs [describe log rotation](https://manual.seafile.com/deploy/using_logrotate.html) in detail, here are my settings:

```shell
# /etc/logrotate.d/seafile
/home/seafile/logs/seafile.log
{
        daily
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
        sharedscripts
        postrotate
                [ ! -f /home/seafile/pids/seaf-server.pid ] || kill -USR1 `cat /home/seafile/pids/seaf-server.pid`
        endscript
}

/home/seafile/logs/ccnet.log
{
        daily
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
        sharedscripts
        postrotate
                [ ! -f /home/seafile/pids/ccnet.pid ] || kill -USR1 `cat /home/seafile/pids/ccnet.pid`
        endscript
}
```

## Fail2ban rules

Seafile automatically logs every third failing login attempt in its logfile. By using an admin account you can configure if accounts shall be locked when entering too many bad passwords. However, in order to prevent people trying to brute-force access to your Seafile installation, it makes sense to ban the malicious IPs automatically using fail2ban (which I would suggest using for SSH, also):

```shell
# /etc/fail2ban/jail.local
[seafile]

enabled  = true
port     = https
filter   = seafile-auth
logpath  = /home/seafile/logs/seahub.log
maxretry = 3
```

And the mentioned filter definition:

```shell
# /etc/fail2ban/filter.d/seafile-auth.conf
# Fail2Ban filter for seafile

[INCLUDES]
before = common.conf

[Definition]
_daemon = seaf-server
failregex = Login attempt limit reached.*, ip: <HOST>
ignoreregex =
```

Both settings are adapted from [the official documentation](https://manual.seafile.com/security/fail2ban.html).

## Backups

Backups have a [section in the docs](https://manual.seafile.com/maintain/backup_recovery.html). I have created a simple shell script from the description and put it into the `seafile` user's crontab for a daily routine:

First, create a backup folder (for me it's on the same external hard drive, which may not be the best solution):

```shell
mkdir -p /media/ext_hd/seafile-backup/{data,database}
chown -R seafile:seafile /media/ext_hd/seafile-backup
```

Script for creating DB and file backups:

```shell
# /home/seafile/seafile-backup.sh

#!/usr/bin/env bash
# ######################################################################
# Creates backup of Seafile data and databases
# Docs at https://manual.seafile.com/maintain/backup_recovery.html
# ######################################################################

SEAFILE_HOME=/home/seafile
SEAFILE_BIN=${SEAFILE_HOME}/seafile-server-latest
SEAFILE_DATA=/media/ext_hd/seafile-data
SEAFILE_BAK=/media/ext_hd/seafile-backups

${SEAFILE_BIN}/seafile.sh stop
${SEAFILE_BIN}/seahub.sh stop

# Backup database contents
sqlite3 ${SEAFILE_HOME}/ccnet/GroupMgr/groupmgr.db .dump > ${SEAFILE_BAK}/databases/groupmgr.db.bak.`date +"%Y-%m-%d-%H-%M-%S"`
sqlite3 ${SEAFILE_HOME}/ccnet/PeerMgr/usermgr.db .dump > ${SEAFILE_BAK}/databases/usermgr.db.bak.`date +"%Y-%m-%d-%H-%M-%S"`
sqlite3 ${SEAFILE_DATA}/seafile.db .dump > ${SEAFILE_BAK}/databases/seafile.db.bak.`date +"%Y-%m-%d-%H-%M-%S"`
sqlite3 ${SEAFILE_HOME}/seahub.db .dump > ${SEAFILE_BAK}/databases/seahub.db.bak.`date +"%Y-%m-%d-%H-%M-%S"`

# Backup file contents
rsync -az ${SEAFILE_DATA} ${SEAFILE_BAK}/data/

# Start server again
${SEAFILE_BIN}/seafile.sh start
${SEAFILE_BIN}/seahub.sh start-fastcgi

exit 0
```

And after having tested it properly, we can add it to the user's crontab:

```shell
crontab -e

# add:
SHELL=/bin/bash
@midnight $HOME/seafile-backup.sh | tee -a $HOME/seafile-backup.log
```

## Clients

There are various clients available for Linux, MacOS and Windows and also as mobile apps for Android and iOS devices: [https://www.seafile.com/en/download/](https://www.seafile.com/en/download/).

## Documentation and useful links

- [Official Server Manual](https://www.gitbook.com/book/freeplant/seafile-server-manual/details)
- [Linux Installation](https://manual.seafile.com/deploy/using_sqlite.html)
- [Release Packages for the RaspberryPi (armhf)](https://github.com/haiwen/seafile-rpi/releases)
- [Troubleshooting aarch64 / armhf compatibility](https://forum.seafile.com/t/seafile-server-on-arm64-aarch64-working/1405/3)
- [Another forum thread describing armhf incompatibilities](http://forum.openmediavault.org/index.php/Thread/12904-How-to-install-Seafile-with-MySQL-and-SSL/?pageNo=6)
- [EFF Docs for using Certbot / Letsencrypt with Apache on Ubuntu 16.04](https://certbot.eff.org/#ubuntuxenial-apache)

Thanks for reading!



