# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

# YAML => JSON
TRANSFORMER=./util/yaml_to_json.py
INPUT_FILE=./packer.yaml
PACKER=packer
PACK_SECRETS=./util/pack_secrets.py

FILES_TAR=files.tar
SECRETS_FILE=fake_secrets.yaml
SECRETS_TAR=secrets.tar

# default_scripts: all scripts in scripts/default, comma separated
PACKER_VARS=-var default_scripts="$(shell ls -m scripts/default/* | tr -d '[:space:]')"
PACKER_VARS+=-var docker_worker_scripts="$(shell ls -m scripts/docker-worker/* | tr -d '[:space:]')"
PACKER_VARS+=-var generic_worker_scripts="$(shell ls -m scripts/generic-worker/* | tr -d '[:space:]')"

ARTIFACTS=packer-artifacts.json $(FILES_TAR) $(SECRETS_TAR) output-vagrant *.log *.pem

DOCKER_IMAGE=monopacker:build

dockerimage: clean tar
	docker build -t $(DOCKER_IMAGE) .

# default if not set
dockervalidate dockerbuild: export GOOGLE_APPLICATION_CREDENTIALS ?= /tmp/you_forgot_google_application_credentials
dockervalidate dockerbuild: PACKER_ARGS=-except vagrant
dockervalidate: clean tar dockerimage
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
		$(DOCKER_IMAGE)

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
		/bin/bash -c "time cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -"

build: clean tar validate
	time cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -

vagrant: PACKER_ARGS=-only vagrant
vagrant: build

tar:
	tar cf $(FILES_TAR) ./files
	$(PACK_SECRETS) $(SECRETS_FILE) $(SECRETS_TAR)

validate: clean tar
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) validate $(PACKER_VARS) $(PACKER_ARGS) -

debug:
	time cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -debug -

clean:
	rm -rf $(ARTIFACTS)
