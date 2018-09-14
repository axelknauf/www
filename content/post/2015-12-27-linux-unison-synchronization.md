---
date: "2015-12-27"
title: 'Linux: Keeping files in sync with unison'
layout: post
---

In this post I would like to describe how to keep files in sync across two (or more) computers using a central storage and the useful tool `unison`.

<!--more-->

## Preparations

In order to synchronize files across machines, you need the following:

* a folder on each machine which shall serve as synchronization point
* a central storage, e. g. an SMB file share or some similar storage (may be SSH, ..)
* the relevant software on each machine, details below

### Required Software

I am running Ubuntu 15.10 on each machine, but the packages required are available for many distros, so this may easily work for you.

        sudo apt-get install cifs-utils unison-gtk

I am using `cifs-utils` to locally mount a centrally-shared SMB drive (actually a USB thumb drive plugged into my Fritz Box and shared via SMBFS from there).

## Setting up CIFS

In order to be able to locally mount the SMB share you first need to make it available on your host. Im my case - I am using a Fritz Box - this was quite easy, I will not write about this here. After having made it available on the network, you can mount it locally using these steps (derived from [this answer](http://askubuntu.com/a/157140)):


First, create a credentials file in your home folder:

        vim ~/.smbcredentials

Put your configuration settings in there:

        username=username
        password=secret_password
        domain=workgroup_name

Make sure the file is only readable by your own user:

        chmod 600 ~/.smbcredentials

Then, create a mount point where you want to have it available on your machine:

        sudo mkdir /media/shared

Having set up the SMB credentials and the mount point, you can add the file share to your `/etc/fstab` so it gets automatically mounted each time you boot:

        sudoedit /etc/fstab

Add a line similar to the following - you will have to adjust the values to fit your own paths and UID/GID. If you are unsure about the IDs, check the output of `id` for your user:

        //server/share-name /media/shared cifs credentials=/home/username/.smbcredentials,uid=1000,gid=1000 0 0

If all pieces fit together you can now mount the share with

        sudo mount -a

Now you have the remote folder mounted locally. Next we create a local folder in your home which shall be kept in sync with the remote one:

        mkdir ~/shared

## Setting up `unison`

Setting up unison is straight-forward. Usually being a CLI user, I went for the GTK UI this time. If your have not run unison before, it will automatically launch the new profile wizard to guide you through the process. Create a new profile, choose `~/shared` as first folder, then `/media/shared` as second folder and make sure to check the box for FAT FS compatibility, since the SMB share does not know about unix permissions and will yield errors if you omit it. In case you do, simple re-create the profile with the correct settings this time.

After having created the profile, unison will attempt an initial synchronization. You will get a warning message telling that there have been no archive folders, yet. This is okay, they are created when you first run unison and trigger the synchronization.

As result of the first synchroniation, `unison` will tell you about the differences, before anything happens. You can review the list of actions and if all is well, simple click on the "Go!" button to start the synchronization. During the first synch, it may well take some time, depending on the amount of data transferred and your network connection speed.

## Adding a second machine

Adding a second machine to synchronize looks identical to the first. You install the software, set up the SMB mount, configure unison and let it run. However, there may be different results depending on the starting conditions. 

If the second machine did not have any files previously, `unison` will download everything initially, and you are fine. In case you already had a - mostly identical - copy of the shared files locally, `unison` may present you with a list of changed / updated files and you can choose how to synchronize them.

## Synchronization Strategies

As described in [the official documentation](http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html), the best strategy to keep multiple machines in sync is to set up a spokes-and-hub network. This means that each client machine synchronizes with a central hub, much like many centrally managed SCMs work. Unison itself only supports two-node-synchronization, but running a central server like the SMB share above, solves this issue easily.

I hope this guide was useful. Happy hacking!

## Links and docs

* Official homepage: [http://www.cis.upenn.edu/~bcpierce/unison/docs.html](http://www.cis.upenn.edu/~bcpierce/unison/docs.html)
* Documentation below: [http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html](http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html)


