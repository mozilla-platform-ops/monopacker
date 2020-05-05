# Monopacker

## Purpose

The intention here is to create a single Packer + cloud-init configuration set that can be used across cloud providers to configure taskcluster worker instances.

## Goals

- Debugability: we should be able to run everything locally as well as in cloud providers
- Clarity: it should be clear which steps run on base images and which steps run on derived images
- Portability: the configuration should be generic enough to be run beyond Firefox CI's worker deployment

## Installation

### Dependencies (alternatively, use docker)

- `pipenv`
  - Note: you can install all python dependencies using `pipenv` (`pipenv install`)
  - If you do that, you probably want to be in a `pipenv shell`
- `make`
- `packer` (`go get github.com/hashicorp/packer`)
- `vagrant`

### Pre-requisites

- If building AWS AMIs you should have:
  - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, environment variables, representing your AWS Access Key and AWS Secret Key, respectively. [(see here)](https://www.packer.io/docs/builders/amazon.html#environment-variables)
  - You need a whole set of IAM privileges, see [here](https://www.packer.io/docs/builders/amazon.html#iam-task-or-instance-role)
- If building Google Cloud Images you should have done one of:
  - run `gcloud auth application-default login` which creates `$HOME/.config/gcloud/application_default_credentials.json`
  - Configured Service Account credentials and have a JSON file whose location is specified by the GOOGLE_APPLICATION_CREDENTIALS environment variable.
  - In either case you need `Compute Engine Instance Admin (v1)` permissions, if using a service account you'll need `Service Account User`. See [here](https://www.packer.io/docs/builders/googlecompute.html#precedence-of-authentication-methods) for more information.

## Usage

### Building Images

Non-docker invocation:

```
# packer build
make build
# get real debug logging from packer
PACKER_LOG=1 make build
# pass additional args to packer
make build PACKER_ARGS="-only vagrant"
# same as above
make vagrant
```

Docker invocation:

*Note*: vagrant builds are unsupported in Docker, see FAQ

Set up:
```bash
# builds and tags a docker container to run monopacker in
# monopacker:build by default, can override DOCKER_IMAGE make var
make dockervalidate
```

Build images:
```bash
# look ma, no dependencies!
make dockerbuild SECRETS_FILE=./real_secrets.yaml
```

You can override a few Make variables (with assignemnts after `make build` or `make dockerbuild`, as in the examples above:

* `SECRETS_FILE`: path to a local file containing secrets (see below)
* `BUILDERS`: builders to set up
* `PACKER_VARS`: packer variables
* `PACKER_ARGS`: additional arguments to packer

Note that there are two ways to build only a single builder: `make .. BUILDERS=mybuilder` or `make .. PACKER_ARGS='-only mybuilder'`.
The first produces a Packer config, naming only `mybuilder`, while the second produces a full Packer config but instructs Packer to only build `mybuilder`.
In practice there is not much difference between the two options.

### Developing Templates

```bash
# generate packer.yaml from packer.yaml.jinja2
make templatepacker

# this runs ./util/template_packer.py
# by default, the BUILDERS arg to the Makefile
# templates certain builders

# you can control which builders are templated:
make templatepacker BUILDERS=docker_worker_aws

# once you are happy with packer.yml, begin invoking
# Packer on it with `make build` or `make dockerbuild` as above.
```

See [TEMPLATING.md](./TEMPLATING.md) for information, another FAQ, and more.

# FAQ

## I'm getting `ModuleNotFoundError: No module named 'ruamel'`

Make sure you're in a `pipenv shell`.

## How do I build using only a single builder?

```bash

# all the debug output
PACKER_LOG=1 VAGRANT_LOG=debug make build BUILDERS=vagrant_virtualbox_bionic
```

```bash

# with a templated packer.yaml, this is simple

# your packer.yaml has only the builders you specify:

make templatepacker BUILDERS=vagrant_virtualbox_bionic

# note that for now, packer.yaml.old is default

make build INPUT_FILE=packer.yaml

```

## How are secrets handled?

```bash

# create a yaml file of the form:

cat << EOF > fake_secrets.yaml
- name: foo
  path: /path/to/foo
  value: what
- name: bar
  path: /path/to/bar
  value: yeah

EOF

# creates secrets.tar by default

./util/pack_secrets.py fake_secrets.yaml

# note that make handles this for you

# for a custom secrets file, pass SECRETS_FILE to make:

make build SECRETS_FILE="/path/to/secrets.yaml"

# for example
make dockerbuild SECRETS_FILE="./real_secrets.yaml"

# by default ./fake_secrets.yaml is used

```

## Why are Packer communicator (SSH) timeouts so long?

AWS Metal instances take a _long_ time to boot. See [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose-instances.html).

> Launching a bare metal instance boots the underlying server, which includes verifying all hardware and firmware components. This means that it can take 20 minutes from the time the instance enters the running state until it becomes available over the network.

## Why can't I build Vagrant VMs in Docker?

You can technically do this, but only on an OS that runs Docker natively.
macOS runs Docker in a Linux VM under the hood, which means you can't do this easily.
Mostly, I just haven't tried to make this work.
