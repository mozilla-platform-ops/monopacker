# Theory of Operation

At a high level, monopacker constructs a [Packer](https://www.packer.io/docs/) configuration and then invokes packer for you.
So understanding the basic concepts of Packer (builders, provisioners, and so on) is critical to understanding how Monopacker works.

The following is a "top-down" description of how Monpacker operates.
The "bottom" is where most of the interesting stuff occurs, so read on!

**Warning** some words here have multiple meanings!
 * *template* - We use Jinja2 templates (textually substituting things like `{{..}}`) as well as a Packer template (which is just what Packer calls its input data)
 * *builder* - Monpacker defines Monopacker builders that map loosely to Packer builders, but also specify scripts that are included in Packer provisioners.

## Packer Template

At the top level, monopacker builds a "Packer template", which is the input to the Packer executable.
The Packer docs explain in detail the contents of this file.

In this Packer template, each Monopacker builder defined in `builders/` is included as a Packer builder.
The Packer provisioners are set up such that, after some initial shared setup, one provisioner runs for each builder.
This is a `shell` provisioner for linux builders and a `powershell` provisioner for windows builders, configured to run the scripts for that builder.

## Monopacker Builders

There is a one-to-one correspondance between Monopacker builders and images (ignoring duplication of images to multiple regions).
That is, there is a distinct builder defined for each necessary combination of worker implementation, cloud, and platform.
Additional builders can be defined for specific purposes, such as specific software installed or specific secrets.

Since this arrangement results in a great deal of duplication across builders, the configuration is designed to maximize the reuse of components.

Each builder is defined in a YAML file in `./builders`.
The builder's YAML file must specify a `template`, which corresponds to a [Jinja2](https://jinja.palletsprojects.com/) template file in `./template/builders`.
Builders can specify any template, and multiple builders can specify the same template.

Builders have a few pieces of configuration:

- `template` (required): which template in ./template/builders to use
- `platform` (required): the os the builder uses, such as linux or windows
- `builder_var_files` and `builder_vars`: variables for use in the template (see below)
- `script_directories`: directories containing scripts to run to build the image

Reuse is accomplished through sharing variable files and script directories between builders.
For example, a script directory `foo-worker-linux` might configure the foo-worker implementation on linux.
This would then be included in `script_directories` for the `foo-worker-linux-azure`, `foo-worker-linux-aws`, and `foo-worker-linux-alibaba` builders.

### Variables

Templates typically have variables that must be specified. For example,
the `vagrant` builder references the following variables:

```
builder.vars.base_image_name
builder.vars.image_suffix
builder.vars.source_path
builder.vars.provider
```

These come from `builder_var_files` or from `builder_vars` set in the builder.

The builder can specify `builder_var_files`:

```
builder_var_files:
  - default_linux
  - vagrant_virtualbox
```

Which refer to YAML files in the `./template/vars` directory.
Variables redefined in multiple `builder_var_files` will be overwritten by each subsequent file as it is loaded.
`builder_vars` override any variables specified in `builder_var_files`.
Variables are merged deeply, with sub-dictionaries also merged recursively.

Note that in the builder template variables are namespaced under `builder.vars` -
this avoids conflicts in templating where multiple builders specify the same variables.

In the `builder_var_files` and `builder_vars` these variables do not have a namespace prefix.
A complete variable file for the `vagrant` builder might look like this:

```
base_image_name: vagrant-builder-worker
image_suffix: docs-edition
source_path: ubuntu/bionic64
provider: virtualbox
```

Alternatively, those variables could have been specified in the builder's YAML file
as a YAML map under the key `builder_vars`, which also serves to override variables
that have already been set by one of the `builder_var_files` specified.

Like scripts, variables allow reuse.
A common tactic is to provide a `defaults` file as well as purpose-specific files that override some of the defaults.
For example `default_linux` might provide some default variables for a linux environment, with `aws_bionic` overriding some of those for Ubuntu Bionic on AWS.

#### Special Variables

A few variables get special treatment.

Environment variables in `builder.vars.env_vars` will be set for all scripts.
These are specified as a dictionary in the builder vars, and automatically converted to `NAME=value` format for Packer.

The required variable `builder.vars.execute_command` sets the Packer `execute_command` configuration.
Similarly, `builder.vars.ssh_timeout` sets the Packer `start_retry_timeout` configuration.

### Scripts

Monopacker runs scripts in the order you specify.
When you specify `script_directories`, all scripts in each of those directories are
executed first by order of directories in the list, then by lexicographic order
of script names in each directory.

For example, if your builder specifies:

```
script_directories:
- my_scripts
- my_other_scripts

# ls -1 my_scripts
01-foo.sh
02-bar.sh

# ls -1 my_other_scripts
0001-qux.sh
```

- All scripts in `my_scripts` will be executed before any scripts in `my_other_scripts`.
- Scripts `my_scripts` will be executed in lexicographic order, so `01-foo.sh` will
  be executed before `02-bar.sh`.

## Secrets

Secrets are handled in code shared between all builders and providers.
A run of `monopacker build` takes a `--secrets_file=..` option pointing to a file containing serets, with the format

```yaml
---
- name: cookie-recipe
  path: /etc/bakery/recipes/cookie.txt
  value: |
    1 part sugar
    ...
```

Each item in the file has a name (optional), a path to which it should be written on the built instances, and the value of the secret.

Secrets are internally written to a tarfile which is transferred to the instance and untarred there.

# How-To

## Add a new builder

Adding a builder is as simple as adding a YAML file, specifying a template,
and making sure that the template's variables are all accounted for by a combination of
`builder_var_files` and `builder_vars`.

## Add a new builder template

In the unlikely scenario that you want to add an entirely new builder template
simply create a `.jinja2` file with the name of your choice under `./template/builders`.

Ensure that your builder template has a `name` key set to `{{builder.vars.name}}`, as this is how `monopacker` templating
maps `builders` to `provisioners` in the Packer template.

# FAQ

## I'm getting `did not find expected key` in my template

You might be using `{{foo}}` syntax to reference a variable that does not exist (in this case, foo).
If you're trying to specify variable that Packer will supply, make sure your value is wrapped in quotes.

## My variables aren't making it from by builder template to the generated Packer template

A number of things could be going wrong here.

Ensure that the builder template properly
references all variables as being namespaced under `builder.vars` and that your `builder_var_files`
and `builder_vars` do _not_ have any namespacing. See above for a more thorough description.
