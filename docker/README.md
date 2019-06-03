# [puppetlabs/r10k](https://github.com/puppetlabs/r10k)

does this work?
r10k on a Docker image. Based on Alpine 3.8.

## Configuration

The following environment variables are supported:

- `PUPPERWARE_ANALYTICS_ENABLED`

  Set to 'true' to enable Google Analytics metrics. Defaults to 'false'.

## Analytics Data Collection

The r10k container collects usage data. This is disabled by default. You can enable it by passing `--env PUPPERWARE_ANALYTICS_ENABLED=true`
to your `docker run` command.

### What data is collected?
* Version of the r10k container.
* Anonymized IP address is used by Google Analytics for Geolocation data, but the IP address is not collected.

### Why does the r10k container collect data?

We collect data to help us understand how the containers are used and make decisions about upcoming changes.

### How can I opt out of r10k container data collection?

This is disabled by default.
