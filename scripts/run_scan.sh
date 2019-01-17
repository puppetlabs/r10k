#!/bin/bash
set -ev

if [ ${CHECK} == CXSCAN ]; then
  $USERDIR/CxConsolePlugin-8.80.0/runCxConsole.sh
elif [ ${CHECK} == DUMMY ]; then
  echo "Dummy invocation - scan skipped"
fi
