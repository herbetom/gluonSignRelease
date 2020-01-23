#!/bin/bash

PUBLIC_SIG_KEY='3a00002ecf1392e7ddbb8db395412cdcb5d9cd8e310b486c3ec1fc0bf161195b'

FIRMWARESERVER_HOST='root@tools.ffrn.de'
FIRMWARESERVER_OPTIONS='-p 22'
FIRMWARESERVER_PATH="/var/www/fw.gluon/"


function storeSecretKey() {
    printf "Input password of DB: "
    keepassxc-cli show -k ~/key.key ~/Freifunk.kdbx signkey -a Password --quiet > $PATH_TO_SECRET_SIG_KEY
    printf "\n"
}
