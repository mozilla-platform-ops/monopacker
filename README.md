# Monopacker

## Purpose

The intention here is to create a single Packer + cloud-init configuration set that can be used across cloud providers to configure taskcluster worker instances.

## Goals

- Debugability: we should be able to run everything locally as well as in cloud providers
- Clarity: it should be clear which steps run on base images and which steps run on derived images
- Portability: the configuration should be generic enough to be run beyond Firefox CI's worker deployment

### Installation

### Dependencies

- `packer` (`go get github.com/hashicorp/packer`)
- `vagrant` (if building a local image)

### Pre-requisites

- If building AWS AMIs you should have:
  - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, environment variables, representing your AWS Access Key and AWS Secret Key, respectively. [(see here)](https://www.packer.io/docs/builders/amazon.html#environment-variables)
  - Run the following command to get temporary credentials:
    ```bash
    eval "$(./aws-signin.sh)"
    ```
  - You need a whole set of IAM privileges, see [here](https://www.packer.io/docs/builders/amazon.html#iam-task-or-instance-role)
- If building Google Cloud Images you should have done one of:
  - run `gcloud auth application-default login` which creates `$HOME/.config/gcloud/application_default_credentials.json`
  - Configured Service Account credentials and have a JSON file whose location is specified by the GOOGLE_APPLICATION_CREDENTIALS environment variable.
  - In either case you need `Compute Instance Admin (v1)` permissions, if using a service account you'll need `Service Account User`. See [here](https://www.packer.io/docs/builders/googlecompute.html#precedence-of-authentication-methods) for more information.

### Install locally

#### Install Poetry and Python dependencies

Install Poetry (https://python-poetry.org/) if you don't already have it.

```shell
# create and activate a poetry virtualenv for this repo
poetry shell

# install package
poetry install
```

#### Install the GCP plugin for Packer

```bash
packer plugins install github.com/hashicorp/googlecompute
```

## Usage

See `monopacker --help` for details.

### Building Images

You will need to know the builder or builders you want to build; `builder1 builder2` are used in the example here.

```shell
monopacker build builder1 builder2
```

Note that you can get more logging from packer by setting `PACKER_LOG=1`.

### Developing Templates

When developing templates, you can run the validation without running packer with `monopacker validate` (which otherwise has the same arguments as `monopacker build`):

```shell
monopacker validate mynewbuilder
```

To see the generated packer template:
```shell
monopacker packer-template mynewbuilder
```

See [TEMPLATING.md](./TEMPLATING.md) for information, another FAQ, and more.

# FAQ

## I'm getting `ModuleNotFoundError: No module named 'ruamel'`

Make sure that you are operating in a Python virtualenv and have installed the package.

## How do I build using only a single builder?

```bash

# all the debug output
PACKER_LOG=1 VAGRANT_LOG=debug monopacker build my_builder
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

# for a custom secrets file, pass --secrets_file to monopacker:
monopacker build --secrets_file="/path/to/secrets.yaml" mybuilder

# by default ./fake_secrets.yaml is used
```

## Why are Packer communicator (SSH) timeouts so long?

AWS Metal instances take a _long_ time to boot. See [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose-instances.html).

> Launching a bare metal instance boots the underlying server, which includes verifying all hardware and firmware components. This means that it can take 20 minutes from the time the instance enters the running state until it becomes available over the network.

## Why can't I build Vagrant VMs in Docker?

You can technically do this, but only on an OS that runs Docker natively.
macOS runs Docker in a Linux VM under the hood, which means you can't do this easily.
Mostly, I just haven't tried to make this work.

# Development

To run the tests for this library, run `poetry run pytest`.

To update dependencies, run `poetry update`.
