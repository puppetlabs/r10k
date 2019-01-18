#!/bin/bash
set -ev

bundle exec rspec --color --format documentation spec/unit

if [ ${CHECK} == CXSCAN ]; then
  $USERDIR/CxConsolePlugin-8.80.0/runCxConsole.sh
elif [ ${CHECK} == DUMMY ]; then
  echo "Dummy invocation - scan skipped"
fi
