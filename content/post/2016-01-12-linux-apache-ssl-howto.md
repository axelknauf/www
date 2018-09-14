---
date: "2016-01-12"
title: 'Linux: Self-signed certificate for Apache SSL'
---

This article details how to generate an SSL certificate in order to encrypt traffic on an Aache hosted site using HTTPS. The certificate will be self-signed, meaning browsers will still show a warning message when accessing the page.

<!--more-->

This setup is not secure and all code is given as examples only. It is intended for development purposes only. If you want to run your site encrypted with a real certificate, you may want to take a look at [Let's Encrypt](https://letsencrypt.org/).

# Assumptions

This guide refers to Apache 2.2 using OpenSSL to generate the certificate - the same can be achieved for later versions of Apache or even using OpenSSL on Cygwin on Windows.

* Apache 2.2 with mod_ssl support
* OpenSSL already installed (`sudo apt-get install openssl`)
* Editor and browser for testing and configuration

I am assuming that you are using the domaim "www.example.com" for your virtual host. This becomes relevant for the "Common Name" (CN) in the certificate signing request (CSR) below. Please adust this where needed.


# How to create a new certificate

On all prompts you can easily press return to use the default setting, unless I am giving other instructions.

These steps are necessary:

## Create folder and Certification Authority (CA)

I am using a subfolder inside Apaches `conf` folder which allows easy configuration from `httpd.conf`.

        $ cd $APACHE_HOME/conf
        $ mkdir certs
        $ cd certs
        $ /usr/ssl/misc/CA.pl -newca

Passphrase: "example"

Common name: "my-example-ca"

## Create server key

        $ openssl genrsa -des3 -out www.example.com.pem 2048

Passphrase: "example"

## Create Certificate Signing Request (CSR)

Using the newly generated server key above.

        $ openssl req -new -key www.example.com.pem -out www.example.com.csr

Common Name "www.example.com", it must match the domain name of your virtual host!

## Create signed certificate using CA and CSR


        $ openssl ca -in www.example.com.csr -out www.example.com-cert.pem

## Remove passphrase from server key

Since Apache does not support passphrases for server keys (on Windows at least), we have to remove any passphrase used above.

        $ openssl rsa -in www.example.com.pem -out www.example.com-nopassphrase.pem

## Configure Apache


### Edit `httpd.conf`

* Uncomment "LoadModule ssl_module" directive
* Uncomment include for `httpd-ssl.conf`

### Edit `extra/httpd-ssl.conf`

#### General settings

            Listen 443
            AddType application/x-x509-ca-cert .crt
            AddType application/x-pkcs7-crl    .crl
            SSLPassPhraseDialog  builtin
            SSLSessionCache        "shmcb:/path/to/apache/logs/ssl_scache(512000)"
            SSLSessionCacheTimeout  300
            SSLMutex default

You will have to adjust the path to your Apache installation.

#### Create VirtualHost for SSL

            NameVirtualHost www.example.com:443
            <VirtualHost www.example.com:443>

               ServerName www.example.com:443
               ServerAdmin root@localhost

               [..]

               SSLEngine on
               SSLProxyEngine On
               SSLProtocol all -SSLv2
               SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5
               SSLCertificateFile "/path/to/apache/conf/certs/www.example.com-cert.pem"
               SSLCertificateKeyFile "/path/to/apache/conf/certs/www.example.com-nopassphrase.pem"

               [..]

            </VirtualHost>

You have to adjust the paths for the Apache installation and both "SSLCertificateFile" and "SSLCertificateKeyFile". In addition, you have to adjust the hostname, of course.

#### Restart Apache

Then, try https://www.example.com/

# Renew an existing certificate

If the certifcate expired (usually it is valid for a single year), it can be renewed using the following steps. We are using the same tools as above, and the examples assume you are in the "certs" folder of your Apache configuration.

## Remove old certifcate from store

Find out the ID of the current certifcate, it is part of `demoCA/index.txt` with your Common Name (above: "www.example.com"):

        $ less demoCA/index.txt
        V       171207033254Z           CC61BF56E46A51BE        unknown /C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=my-example-ca
        V       151208033429Z           CC61BF56E46A51BF        unknown /C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=www.example.com    <--------------

In this case it is the second one, the common name is at the very end and we note the ID "CC61BF56E46A51BF" (third column). There if a file with this ID as name in the `newcerts` folder:

        $ ls -l demoCA/newcerts
        ..
        -rw-r--r-- 1 user group 2999  8. Dez 2014  CC61BF56E46A51BE.pem
        -rw-r--r-- 1 user group 3891  8. Dez 2014  CC61BF56E46A51BF.pem   <------------

When we have the file, we can revoke the certifcate using the passphrase from above:

        $ openssl ca -revoke demoCA/newcerts/CC61BF56E46A51BF.pem
        Using configuration from /usr/ssl/openssl.cnf
        Enter pass phrase for ./demoCA/private/cakey.pem:
        Revoking Certificate CC61BF56E46A51BF.
        Data Base Updated

## Create a new certificate

Afterwards a new one can be generated using the existing CSR from the initial creation. If you do not have this file anymore, you can follow the steps above to create a new one.

        $ openssl ca -in www.example.com.csr -out www.example.com-cert.pem

If you want to use this new certificate in Apache, you will have to remove the passphrase again. Afterwards, place the new certificate file in the Apache config folder and restart the server.

# Links and Documentation

* Official Apache 2.2 SSL docs: [http://httpd.apache.org/docs/2.2/en/ssl/](http://httpd.apache.org/docs/2.2/en/ssl/)
* Let's Encrypt open CA: [https://letsencrypt.org/](https://letsencrypt.org/)
* OpenSSL 1.0.2 man page: [https://www.openssl.org/docs/man1.0.2/apps/openssl.html](https://www.openssl.org/docs/man1.0.2/apps/openssl.html)

