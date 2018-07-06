ARG namespace="puppet"
ARG puppet_agent_version="latest"
FROM "$namespace"/puppet-agent-ubuntu:"$puppet_agent_version"

ARG vcs_ref
ARG build_date
ARG version="2.5.5"
ENV R10K_VERSION="$version"

LABEL org.label-schema.maintainer="Puppet Release Team <release@puppet.com>" \
      org.label-schema.vendor="Puppet" \
      org.label-schema.url="https://github.com/puppetlabs/r10k" \
      org.label-schema.name="r10k" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.version="$R10K_VERSION" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/r10k" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

RUN apt-get update && \
    apt-get install --no-install-recommends -y git openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN /opt/puppetlabs/puppet/bin/gem install r10k:"$R10K_VERSION"

ENTRYPOINT ["/opt/puppetlabs/puppet/bin/r10k"]
CMD ["help"]

COPY Dockerfile /
