#! /bin/sh

set -ue

for f in /docker-entrypoint.d/*.sh; do
  # Don't print out any messages here since this is a CLI container
  su "${PP_USER}" -- "${f}"
done

for f in /docker-custom-entrypoint.d/*.sh; do
  # Don't print out any messages here since this is a CLI container
  [ -x "${f}" ] && "${f}"
done

exec su "${PP_USER}" -c "/usr/bin/r10k $*"
