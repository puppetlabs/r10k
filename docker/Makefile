git_describe = $(shell git describe)
vcs_ref := $(shell git rev-parse HEAD)
build_date := $(shell date -u +%FT%T)
hadolint_available := $(shell hadolint --help > /dev/null 2>&1; echo $$?)
hadolint_command := hadolint --ignore DL3008 --ignore DL3018 --ignore DL4000 --ignore DL4001
hadolint_container := hadolint/hadolint:latest

ifeq ($(IS_NIGHTLY),true)
	dockerfile := Dockerfile.nightly
	version := puppet6-nightly
else
	version = $(shell echo $(git_describe) | sed 's/-.*//')
	dockerfile := Dockerfile
endif


prep:
ifneq ($(IS_NIGHTLY),true)
	@git fetch --unshallow ||:
	@git fetch origin 'refs/tags/*:refs/tags/*'
endif

lint:
ifeq ($(hadolint_available),0)
	@$(hadolint_command) r10k/$(dockerfile)
else
	@docker pull $(hadolint_container)
	@docker run --rm -v $(PWD)/r10k/$(dockerfile):/Dockerfile -i $(hadolint_container) $(hadolint_command) Dockerfile
endif

build: prep
	@docker build --pull --build-arg vcs_ref=$(vcs_ref) --build-arg build_date=$(build_date) --build-arg version=$(version) --file r10k/$(dockerfile) --tag puppet/r10k:$(version) r10k
ifeq ($(IS_LATEST),true)
	@docker tag puppet/r10k:$(version) puppet/r10k:latest
endif

test: prep
	@bundle install --path .bundle/gems
	@PUPPET_TEST_DOCKER_IMAGE=puppet/r10k:$(version) bundle exec rspec r10k/spec

publish: prep
	@docker push puppet/r10k:$(version)
ifeq ($(IS_LATEST),true)
	@docker push puppet/r10k:latest
endif

.PHONY: lint build test publish
