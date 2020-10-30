#!/bin/bash

if [ "$#" -ne 5 ] ; then
    echo "HELP: $0 <user> <password> <server> <local> <remote>"
    exit 1
fi

FTPUSER=$1
FTPPWD=$2
FTPSERVER=$3
LOCAL=$4
REMOTE=$5

if [ ! -d "$LOCAL" ] ; then
    echo "Local directory doesn't exist, please check!"
    exit 1
fi

echo "Start deploy local $LOCAL to remote $REMOTE"

lftp -u$FTPUSER,$FTPPWD $FTPSERVER \
    -e "set net:timeout 5; set net:max-retries 1; \
    set net:reconnect-interval-base 3; \
    mirror --parallel=4 -p -e -R $LOCAL $REMOTE ; bye"
