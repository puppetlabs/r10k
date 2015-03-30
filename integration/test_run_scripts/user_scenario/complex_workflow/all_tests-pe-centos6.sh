#!/bin/bash
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "complex_workflow" ]; then
  cd ../../../
fi

export pe_dist_dir=http://neptune.puppetlabs.lan/3.8/ci-ready/
export GIT_PROVIDER=shellgit

beaker \
  --preserve-hosts onfail \
  --config configs/pe/centos-6-64mda \
  --debug \
  --tests tests/user_scenario/complex_workflow \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --pre-suite pre-suite \
  --load-path lib
