FROM alpine:3.9 as build

RUN apk add --no-cache ruby git && \
    mkdir /workspace
WORKDIR /workspace
COPY . /workspace
RUN gem build r10k.gemspec && \
    mv r10k*.gem r10k.gem

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
      org.label-schema.dockerfile="/Dockerfile"

COPY docker/r10k/adduser.sh docker/r10k/docker-entrypoint.sh /
COPY docker/r10k/docker-entrypoint.d /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["help"]

# dyanmic LABELs and ENV vars placed lower for the sake of Docker layer caching
ENV PUPPERWARE_ANALYTICS_STREAM="$pupperware_analytics_stream"

LABEL org.label-schema.version="$version" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date"

COPY --from=build /workspace/r10k.gem /
RUN chmod a+x /adduser.sh && \
# Add a puppet user to run r10k as for consistency with puppetserver
    /adduser.sh && \
    chmod +x /docker-entrypoint.sh && \
    chown -R puppet: /docker-entrypoint.d /docker-entrypoint.sh && \
    apk add --no-cache ruby openssh-client git ruby-rugged curl ruby-dev make gcc musl-dev && \
    gem install --no-doc /r10k.gem json etc && \
    rm -f /r10k.gem

USER puppet
WORKDIR /home/puppet

COPY docker/r10k/Dockerfile /
