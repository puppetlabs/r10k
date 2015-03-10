#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "git_source" ]; then
  cd ../../
fi

export pe_dist_dir=http://pe-releases.puppetlabs.lan/3.7.1/

beaker \
  --preserve-hosts onfail \
  --config configs/pe/centos-6-64mda \
  --debug \
  --tests tests/git_source \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --pre-suite pre-suite \
  --load-path lib
