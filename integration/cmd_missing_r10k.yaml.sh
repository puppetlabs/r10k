#!/bin/bash

#~/repos/r10k/integration/tests/user_scenario/basic_workflow/multi_env_1000_branches.rb
export MANIFESTS=~/repos/r10k/integration/manifests
export FILES=~/repos/r10k/integration/files
export pe_dist_dir=http://pe-releases.puppetlabs.lan/3.7.1/
beaker \
  --config ~/repos/r10k/integration/configs/pe/centos-7-64mda \
  --debug \
  --load-path ~/repos/r10k/integration/lib \
  --pre-suite ~/repos/r10k/integration/tests/missing_r10k_yaml_pre-suite \
  --tests ~/repos/r10k/integration/tests/user_scenario/basic_workflow/deploy_r10k_with_missing_yaml.rb \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --timeout 6000
