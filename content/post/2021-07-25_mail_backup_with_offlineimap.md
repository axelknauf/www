---
title: "Backup IMAP mails with offlineimap"
date: 2021-07-25T09:13:30+02:00
draft: false
---

# Motivation

My [email provider](https://posteo.de) is awesome, but the default mailbox size is 2G. In fact, this is a good thing because it forces me to clean up my mails from time to time. Today is such a day. But since I do not want to lose my old mail archives I wanted to create a backup of my full IMAP account first. Here's what I did.

# OfflineIMAP

[offlineimap](http://offlineimap.org) is the perfect tool for the job. It's designed to download an IMAP account to local Maildir (or other format) folders. Synchronising my account was as simple as installing it and creating a minimalist configuration. I am running Debian stable (buster), so the commands required may vary for you.

    sudo apt install offlineimap

    mkdir ~/backups/mails-202107
    cp /usr/share/doc/offlineimap/examples/offlineimap.conf.minimal ~/.offlineimaprc
    vim $!

    # edit config (see below) and then run:
    offlineimap

    # enter password when asked, then wait until it's done

As usual, the [Arch Wiki](https://wiki.archlinux.org/title/OfflineIMAP) has some great documentation. Here's my configuration:


    [general]
    accounts = posteo

    [Account posteo]
    localrepository = Local
    remoterepository = Remote

    [Repository Local]
    type = Maildir
    localfolders = ~/backups/mails-202107

    [Repository Remote]
    type = IMAP
    remotehost = posteo.de
    remoteuser = <my email address>
    ssl=yes
    sslcacertfile=OS-DEFAULT

That's it. Atferwards I could securely delete all the remote stuff I did not need anymore. 

# Reading mails

If I want to read mails from the backup, I can simply open them up in [mutt](http://mutt.org):

    cd ~/backups/mails-202107
    mutt -R -f INBOX

