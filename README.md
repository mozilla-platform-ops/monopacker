### Purpose

The intention here is to create a single Packer + cloud-init configuration set that can be used across cloud providers to configure taskcluster worker instances.

### Goals

- Debugability: we should be able to run everything locally as well as in cloud providers
- Clarity: it should be clear which steps run on base images and which steps run on derived images
- Portability: the configuration should be generic enough to be run beyond Firefox CI's worker deployment

### Dependencies (alternatively, use docker)

- `pipenv`
  - Note: you can install all python dependencies using `pipenv` (`pipenv install`)
  - If you do that, you probably want to be in a `pipenv shell`
- `make`
- `packer` (`go get github.com/hashicorp/packer`)
- `vagrant`

### Pre-requisites

- If building AWS AMIs you should have:
  > AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, environment variables, representing your AWS Access Key and AWS Secret Key, respectively. [(see here)](https://www.packer.io/docs/builders/amazon.html#environment-variables)
- If building Google Cloud Images you should have:
  > A JSON file (Service Account) whose path is specified by the GOOGLE_APPLICATION_CREDENTIALS environment variable. [(see here)](https://www.packer.io/docs/builders/googlecompute.html#precedence-of-authentication-methods)

### Usage (non-docker)

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

### Usage (docker)

#### Note: vagrant builds are unsupported in Docker, see FAQ

```
# builds and tags a docker container to run monopacker in
# monopacker:build by default, can override DOCKER_IMAGE make var
make dockervalidate

# look ma, no dependencies!
make dockerbuild PACKER_ARGS='-only docker_worker_aws' SECRETS_FILE=./real_secrets.yaml
```

### Templating packer.yaml for your builders

```
# generate packer.yaml from packer.yaml.jinja2
make templatepacker

# this runs ./util/template_packer.py
# by default, the BUILDERS arg to the Makefile
# templates certain builders

# you can control which builders are templated:
make templatepacker BUILDERS=docker_worker_aws

# if your builders are configured properly
# a packer.yaml will be generated for your builders
# then you can run normal monopacker Makefile directives:

# note that for now, packer.yaml.old is default
make dockerbuild INPUT_FILE=packer.yaml
```

### Templating packer.yaml and templated builders

See [TEMPLATING.md](./templating.md) for information, another FAQ, and more.

### FAQ

#### How do I build using only a single builder?

```

# example using packer cli

cat ./packer.yaml | ./util/yaml_to_json.py | packer build -only vagrant -

# or, using make

PACKER_LOG=1 make build PACKER_ARGS='-only vagrant'

```

```

# with a templated packer.yaml, this is simple

# your packer.yaml has only the builders you specify:

make templatepacker BUILDERS=vagrant_virtualbox

# note that for now, packer.yaml.old is default

make build INPUT_FILE=packer.yaml

```

#### How are secrets handled?

```

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

# by default ./fake_secrets.yaml is used

```

### Why are Packer communicator (SSH) timeouts so long?

AWS Metal instances take a _long_ time to boot. See [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose-instances.html).

> Launching a bare metal instance boots the underlying server, which includes verifying all hardware and firmware components. This means that it can take 20 minutes from the time the instance enters the running state until it becomes available over the network.

### Why can't I build Vagrant VMs in Docker?

You can technically do this, but only on an OS that runs Docker natively.
macOS runs Docker in a Linux VM under the hood, which means you can't do this easily.
Mostly, I just haven't tried to make this work.
