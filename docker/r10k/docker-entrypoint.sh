#! /bin/sh

set -e

for f in /docker-entrypoint.d/*.sh; do
  echo "Running $f"
  chmod +x "$f"
  "$f"
done

exec /opt/puppetlabs/puppet/bin/r10k "$@"
