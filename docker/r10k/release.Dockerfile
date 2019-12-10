FROM alpine:3.9

ARG vcs_ref
ARG build_date
ARG version="3.1.0"
# Used by entrypoint to submit metrics to Google Analytics.
# Published images should use "production" for this build_arg.
ARG pupperware_analytics_stream="dev"

LABEL org.label-schema.maintainer="Puppet Release Team <release@puppet.com>" \
      org.label-schema.vendor="Puppet" \
      org.label-schema.url="https://github.com/puppetlabs/r10k" \
      org.label-schema.name="r10k" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/r10k" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/release.Dockerfile"

COPY docker-entrypoint.sh /
COPY docker-entrypoint.d /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["help"]

# dyanmic LABELs and ENV vars placed lower for the sake of Docker layer caching
ENV PUPPERWARE_ANALYTICS_STREAM="$pupperware_analytics_stream"

LABEL org.label-schema.version="$version" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date"

RUN chmod +x /docker-entrypoint.sh && \
    apk add --no-cache ruby openssh-client git ruby-rugged curl ruby-dev make gcc musl-dev && \
    gem install --no-doc r10k:"$version" json etc

COPY release.Dockerfile /
