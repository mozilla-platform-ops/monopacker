#### General guidance

#### How does templating work?

Monopacker does things in the order you specify.
When you specify `script_directories`, all scripts in all of those directories are
executed first by order of directories in the list, then by lexicographic order
of script names in each directory.

For example, if your builder specifies:

```
script_directories:
- my_scripts
- my_other_scripts

# ls -1 my_scripts
# 01-foo.sh
# 02-bar.sh

# ls -1 my_other_scripts
# 0001-qux.sh
```

- All scripts in `my_scripts` will be executed before any scripts in `my_other_scripts`.
- Scripts `my_scripts` will be executed in lexicographic order, so `01-foo.sh` will
  be executed before `02-bar.sh`.

The same concept applies to `var_files`. Variables redefined in multiple `var_files`
will be overwritten by each subsequent file as it is loaded.

`override_vars`, as the name implies, override any variables specified in `var_files`.

#### Adding a new templated builder

A builder is defined by a YAML file in the `./builders` directory.
The builder's YAML file must specify a `template`, which corresponds
to a `.jinja2` template file in `./template/builders`. Builders can specify
any template, and multiple builders can specify the same template.

Templates typically have variables that must be specified. For example,
the `vagrant` builder references the following variables:

```
builder.vars.base_image_name
builder.vars.image_suffix
builder.vars.source_path
builder.vars.provider
```

These come from `var_files` or from `override_vars` set in the builder.

The builder can specify `var_files`:

```
var_files:
  - base
  - vagrant_virtualbox
```

Which refer to YAML files in the `./template/vars` directory.

Note that in the builder template variables are namespaced under `builder.vars` -
this avoids conflicts in templating where multiple builders specify the same variables.

In the `var_files` and `override_vars` these variables do not have a namespace prefix.
A complete variable file for the `vagrant` builder might look like this:

```
base_image_name: vagrant-builder-worker
image_suffix: docs-edition
source_path: ubuntu/bionic64
provider: virtualbox
```

Alternatively, those variables could have been specified in the builder's YAML file
as a YAML map under the key `override_vars`, which also serves to override variables
that have already been set by one of the `var_files` specified.

In summary: adding a builder is as simple as adding a YAML file, specifying a template,
and making sure that the template's variables are all accounted for by a combination of
`var_files` and `override_vars`.

### FAQ

#### I'm getting `did not find expected key` in my template

You might be using `{{foo}}` syntax to reference a variable that does not exist (in this case, foo).
If you're trying to specify variable that Packer will supply, make sure your value is wrapped in quotes.

#### My variables aren't making it from by builder template to the generated packer.yaml

A number of things could be going wrong here.

Ensure that the builder template properly
references all variables as being namespaced under `builder.vars` and that your `var_files`
and `override_vars` do _not_ have any namespacing. See above for a more thorough description.
