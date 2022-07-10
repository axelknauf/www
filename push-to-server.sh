#!/usr/bin/env bash

rsync -av --delete public/ kopfkind@192.168.178.27:~/website-staging/

