# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

PACKER=packer
PACK_SECRETS=./util/pack_secrets.py

# for jinja2 templating
TEMPLATER=./util/template_packer.py
TEMPLATE=./packer.yaml.jinja2

# default
BUILDERS=docker_worker_aws docker_worker_gcp

FILES_TAR=files.tar
SECRETS_FILE=fake_secrets.yaml
SECRETS_TAR=secrets.tar

ARTIFACTS=packer-artifacts.json $(FILES_TAR) $(SECRETS_TAR) output-vagrant *.log *.pem

DOCKER_IMAGE=monopacker:build

dockerimage: clean
	docker build -t $(DOCKER_IMAGE) .

# default if not set
dockervalidate dockerbuild: export GOOGLE_APPLICATION_CREDENTIALS ?= /tmp/you_forgot_google_application_credentials
dockervalidate dockerbuild: PACKER_ARGS=-except vagrant
dockervalidate: clean dockerimage tar
	touch $(GOOGLE_APPLICATION_CREDENTIALS)
	docker run \
		--mount type=bind,source="$(shell pwd)",target=/monopacker \
		--mount type=bind,source="$(GOOGLE_APPLICATION_CREDENTIALS)",target="$(GOOGLE_APPLICATION_CREDENTIALS)" \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_SECURITY_TOKEN \
		-e GOOGLE_APPLICATION_CREDENTIALS \
		-e PACKER_LOG \
		-e VAGRANT_LOG \
		$(DOCKER_IMAGE) \
		/bin/bash -c "$(PACK_SECRETS) $(SECRETS_FILE) $(SECRETS_TAR) && \
					  $(TEMPLATER) $(TEMPLATE) $(BUILDERS) | $(PACKER) validate $(PACKER_VARS) $(PACKER_ARGS) -"

dockerbuild: dockervalidate
	docker run \
		--mount type=bind,source="$(shell pwd)",target=/monopacker \
		--mount type=bind,source="$(GOOGLE_APPLICATION_CREDENTIALS)",target="$(GOOGLE_APPLICATION_CREDENTIALS)" \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_SECURITY_TOKEN \
		-e GOOGLE_APPLICATION_CREDENTIALS \
		$(DOCKER_IMAGE) \
		/bin/bash -c "$(PACK_SECRETS) $(SECRETS_FILE) $(SECRETS_TAR) && \
					  time $(TEMPLATER) $(TEMPLATE) $(BUILDERS) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -"

templatepacker:
	$(TEMPLATER) $(TEMPLATE) $(BUILDERS) > packer.yaml

build: clean validate
	time $(TEMPLATER) $(TEMPLATE) $(BUILDERS) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -

vagrant: BUILDERS=vagrant_virtualbox_bionic
vagrant: build

tar:
	tar cf $(FILES_TAR) ./files

packsecrets:
	$(PACK_SECRETS) $(SECRETS_FILE) $(SECRETS_TAR)

validate: clean tar packsecrets
	$(TEMPLATER) $(TEMPLATE) $(BUILDERS) | $(PACKER) validate $(PACKER_VARS) $(PACKER_ARGS) -

clean:
	rm -rf $(ARTIFACTS)
