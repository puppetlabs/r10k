#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "basic_functionality" ]; then
  cd ../../
fi

export pe_dist_dir=http://neptune.puppetlabs.lan/2015.2/ci-ready/
export GIT_PROVIDER=shellgit

beaker \
  --preserve-hosts onfail \
  --config configs/pe/centos-6-64mda \
  --debug \
  --tests tests/basic_functionality \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --pre-suite pre-suite \
  --load-path lib
