# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

PACKER=packer
PACK_SECRETS=./util/pack_secrets.py

# for jinja2 templating
MONOPACKER=./bin/monopacker
TEMPLATE=./packer.yaml.jinja2

# default
BUILDERS=docker_worker_aws docker_worker_gcp docker_worker_azure

FILES_TAR=files.tar
SECRETS_FILE=fake_secrets.yaml
SECRETS_TAR=secrets.tar

ARTIFACTS=packer-artifacts.json $(FILES_TAR) $(SECRETS_TAR) output-vagrant *.log *.pem

templatepacker:
	$(MONOPACKER) packer-template $(TEMPLATE) $(BUILDERS) > packer.yaml

build: clean validate
	/bin/bash -c "time $(MONOPACKER) packer-template $(TEMPLATE) $(BUILDERS) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -"

vagrant: BUILDERS=vagrant_virtualbox_bionic
vagrant: build

tar:
	tar cf $(FILES_TAR) ./files

packsecrets:
	$(PACK_SECRETS) $(SECRETS_FILE) $(SECRETS_TAR)

validate: clean tar packsecrets
	$(MONOPACKER) packer-template $(TEMPLATE) $(BUILDERS) | $(PACKER) validate $(PACKER_VARS) $(PACKER_ARGS) -

clean:
	rm -rf $(ARTIFACTS)

test:
	python -m pytest tests/
