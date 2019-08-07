# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

TRANSFORMER=yq .
INPUT_FILE=./packer.yaml
PACKER=packer

# default_scripts: all scripts in scripts/default, comma separated
PACKER_VARS=-var default_scripts="$(shell ls -m scripts/default/* | tr -d '[:space:]')"
PACKER_VARS+=-var docker_worker_scripts="$(shell ls -m scripts/docker-worker/* | tr -d '[:space:]')"
PACKER_VARS+=-var generic_worker_scripts="$(shell ls -m scripts/generic-worker/* | tr -d '[:space:]')"

ARTIFACTS=packer-artifacts.json files.tar output-vagrant *.log *.pem

build: clean tar validate
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -

vagrant: PACKER_ARGS=-only vagrant
vagrant: build

tar:
	tar cf files.tar ./files

validate: clean tar
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) validate $(PACKER_VARS) $(PACKER_ARGS) -

debug:
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build $(PACKER_VARS) $(PACKER_ARGS) -debug -

clean:
	rm -rf $(ARTIFACTS)
