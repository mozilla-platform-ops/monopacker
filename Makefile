# adapted from https://www.andrewpage.me/infrastructure/2018/05/11/simplify-packer-configuration-with-yaml.html

TRANSFORMER=yq .
INPUT_FILE=./packer.yaml
PACKER=packer

ARTIFACTS=packer-artifacts.json output-vagrant files.tar *.box

validate:
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) validate -

build:
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build -

debug:
	cat $(INPUT_FILE) | $(TRANSFORMER) | $(PACKER) build -debug -

clean:
	rm -rf $(ARTIFACTS)
