#!/bin/bash
set -ev

echo `pwd`

if [ ${CHECK} == CXSCAN ]; then
  $USERDIR/CxConsolePlugin-8.80.0/runCxConsole.sh -v -Projectname "CxServer\r10k" -CxServer http://10.234.4.100 -cxuser admin -cxpassword ChkDemo123* -preset "Checkmarx Default" -LocationType folder -locationpath /home/travis/build/puppetlabs/r10k/
elif [ ${CHECK} == DUMMY ]; then
  echo "Dummy invocation - scan skipped"
fi
