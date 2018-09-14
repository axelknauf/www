---
date: "2015-07-20"
title: Linux Snippets
---

This article collects all kinds of useful tips and tricks around Linux usage, mostly if not all of them about command line tools. Many have been collected over the years, so any advanced user may not find them interesting. But when getting started with the command line, they may still be helpful for new users.

<!--more-->

## Common issues

### "Too many open files"

* check current limit (only valid for executing user): `ulimit -a` or specifically `ulimit -n` (`-n` refers to "number of files")
* set limit with `ulimit -n unlimited` or `ulimit -n 65535` (may result in "permission denied")
* on Fedora: edit `/etc/security/limits.conf`

## Common filesystem tasks

### List folders by size descending recursively

        find . -type d -exec du -b {} \; | sort -nr | uniq

### Latest changed files (one folder deep search)

        find . -maxdepth 2 -type f -exec stat -c %y_%n {} \; | sort -r | less

### 10 latest changed files (recursively)

        find . -type f -printf '%TF_%TT %p \n' | sort -r | head -n 10

### Change file encoding (e. g. from UTF-8)

        recode -f ascii <file>

## Networking and Web

### Use kernel prerouting to direct traffic from port 80 to 8080, e. g. for fronting tomcat

        iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination :8080

### Repeatedly serve a file using netcat (call with wget http://localhost:12345/)

        #!/bin/bash

        while true
        do
          { echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c &lt;file.txt)\r\n\r\n"; cat file.txt; } | nc -l 12345
        done

        exit 0

### Apply htdigest protection to Apache directory

#### Required modules

* `mod_authz_user`
* `mod_auth_digest`
* `mod_authn_file`

#### Configuration

        <Location /path/to/protect>
           AuthType Digest
           AuthName "Protected Area"
           AuthDigestDomain /path/to/protect http://11.22.33.44/path/to/protect
           AuthDigestProvider file
           AuthUserFile /etc/apache2/conf/digest_pw
           Require valid-user
        </Location>

#### Create digest_pw file

        htdigest -c /etc/apache2/conf/digest_pw "Protected Area" username
        => will be asked for password, file created

### Upload multiple files via FTP (which is an interactive tool)

Requires curlftpfs and fuse + rsync

        #!/bin/bash

        SOURCE_DIR=./dist/
        HOST=some.host.com
        USER=username
        PASS=passsword
        TARGET_DIR=/target/
        MOUNT_POINT=./mnt/
        TMP_DIR=$(mktemp -d)

        #########################################################################
        ## Abort if mount point does not exist
        if [ ! -d ${MOUNT_POINT} ];
        then
          echo "Target mount point directory does not exist, aborting."
          exit 1
        fi

        #########################################################################
        ## Mount remote file system locally
        curlftpfs -o user=${USER}:${PASS} ${HOST} ${MOUNT_POINT} || exit 1

        #########################################################################
        ## Transfer files incrementally
        if [ -d "${MOUNT_POINT}/${TARGET_DIR}" ]
        then
            rsync -rtuv --modify-window=1 --delete --no-perms --size-only --temp-dir=${TMP_DIR} ${SOURCE_DIR}/ ${MOUNT_POINT}/${TARGET_DIR}/
        else
            echo "Target remote directory does not exist, aborting."
        fi

        #########################################################################
        ## Unmount remote file system
        fusermount -u ${MOUNT_POINT}

        #########################################################################
        ## Remove temporary directory
        if [ -d "${TMP_DIR}" ];
        then
            rm -rf ${TMP_DIR}
        fi

        exit 0

