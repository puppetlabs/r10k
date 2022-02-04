ARG alpine_version=3.14
FROM alpine:${alpine_version}

ARG vcs_ref
ARG build_date
ARG version="3.1.0"
# Used by entrypoint to submit metrics to Google Analytics.
# Published images should use "production" for this build_arg.
ARG pupperware_analytics_stream="dev"
# required to schedule runs of "r10k" in K8s
ARG supercronic_version="0.1.9"
ARG supercronic_sha1sum="5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85"
ARG supercronic="supercronic-linux-amd64"
ARG supercronic_url="https://github.com/aptible/supercronic/releases/download/v$supercronic_version/$supercronic"

LABEL org.label-schema.maintainer="Puppet Release Team <release@puppet.com>" \
      org.label-schema.vendor="Puppet" \
      org.label-schema.url="https://github.com/puppetlabs/r10k" \
      org.label-schema.name="r10k" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/r10k" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/release.Dockerfile"

COPY adduser.sh docker-entrypoint.sh /
COPY docker-entrypoint.d /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["help"]

# dyanmic LABELs and ENV vars placed lower for the sake of Docker layer caching
ENV PUPPERWARE_ANALYTICS_STREAM="$pupperware_analytics_stream"

LABEL org.label-schema.version="$version" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# ignore apk and gem pinning
# hadolint ignore=DL3018,DL3028
RUN chmod a+x /adduser.sh /docker-entrypoint.sh /docker-entrypoint.d/*.sh && \
    /adduser.sh && \
    chown -R puppet: /docker-entrypoint.d /docker-entrypoint.sh && \
    apk add --no-cache ruby openssh-client git ruby-rugged curl ruby-dev make gcc musl-dev && \
    gem install --no-doc r10k:"$version" json etc && \
    curl --fail --silent --show-error --location --remote-name "$supercronic_url" && \
    echo "${supercronic_sha1sum}  ${supercronic}" | sha1sum -c - && \
    chmod +x "$supercronic" && \
    mv "$supercronic" "/usr/local/bin/${supercronic}" && \
    ln -s "/usr/local/bin/${supercronic}" /usr/local/bin/supercronic

USER puppet
WORKDIR /home/puppet

COPY release.Dockerfile /
