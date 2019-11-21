#!/bin/sh

getent_string="$(getent group | grep -e ':999$')"
exit_code=$?

if [ "$exit_code" = '0' ]; then
  group="$(echo $getent_string | cut -d ':' -f1)"
else
  addgroup -g 999 puppet
  group='puppet'
fi

adduser -G $group -D -u 999 puppet
