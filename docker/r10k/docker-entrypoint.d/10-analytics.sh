#!/bin/sh

if [ "${PUPPERWARE_ANALYTICS_ENABLED}" != "true" ]; then
    echo "($0) Pupperware analytics not enabled; skipping metric submission"
    exit 0
fi

# See: https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
# Tracking ID
tid=UA-132486246-5
# Application Name
an=r10k
# Application Version
av=$R10K_VERSION
# Anonymous Client ID
_file=/var/tmp/pwclientid
cid=$(cat $_file 2>/dev/null || (cat /proc/sys/kernel/random/uuid | tee $_file))
# Event Category
ec=${PUPPERWARE_ANALYTICS_STREAM:-dev}
# Event Action
ea=start

_params="v=1&t=event&tid=${tid}&an=${an}&av=${av}&cid=${cid}&ec=${ec}&ea=${ea}"
_url="http://www.google-analytics.com/collect?${_params}"

echo "($0) Sending metrics ${_url}"
curl --fail --silent --show-error --output /dev/null \
    -X POST -H "Content-Length: 0" $_url
