# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

PACKER=packer

# for jinja2 templating
MONOPACKER=./bin/monopacker
TEMPLATE=./packer.yaml.jinja2

# default
BUILDERS=docker_worker_aws docker_worker_gcp docker_worker_azure

ARTIFACTS=packer-artifacts.json $(FILES_TAR) $(SECRETS_TAR) output-vagrant *.log *.pem

templatepacker:
	$(MONOPACKER) packer-template $(TEMPLATE) $(BUILDERS) > packer.yaml

build: clean validate
	$(MONOPACKER) build $(TEMPLATE) $(BUILDERS)

vagrant: BUILDERS=vagrant_virtualbox_bionic
vagrant: build

validate: clean
	$(MONOPACKER) validate $(TEMPLATE) $(BUILDERS)

clean:
	rm -rf $(ARTIFACTS)

test:
	python -m pytest tests/
