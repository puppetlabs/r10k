#! /bin/sh

set -e

for f in /docker-entrypoint.d/*.sh; do
  # Don't print out any messages here since this is a CLI container
  "$f"
done

exec /usr/bin/r10k "$@"
