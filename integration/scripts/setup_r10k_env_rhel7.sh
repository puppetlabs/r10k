#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "scripts" ]; then
  cd ../
fi

export pe_dist_dir=http://neptune.puppetlabs.lan/4.0/ci-ready/
export GIT_PROVIDER=shellgit

bundle install --path .bundle/gems

bundle exec beaker \
  --preserve-hosts always \
  --config configs/pe/redhat-7-64mda \
  --debug \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --pre-suite pre-suite \
  --load-path lib

rm -rf .bundle
