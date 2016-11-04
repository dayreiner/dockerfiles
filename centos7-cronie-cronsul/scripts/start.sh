#!/bin/bash

#set -x

exec 1> >(logger -s -t $(basename $0)) 2>&1

crontab /cron-jobs

exec /usr/sbin/crond -n -x bit
