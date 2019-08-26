#!/usr/bin/env python3

import sys, argparse, json
from pathlib import Path
from typing import Any, Dict, Sequence

from jinja2 import (
    Environment,
    FileSystemLoader,
    TemplateNotFound,
    TemplateError,
    TemplateSyntaxError,
)

from ruamel.yaml import YAML

yaml = YAML(typ="safe")


def get_files_from_subdirs(*args, root_dir=".", glob="*"):
    """Get an sorted list of files from a list of subdirectories

    keyword arguments:
    root_dir -- root directory in which to look for subdirectories, defaults to '.'
    glob -- glob expression for files in subdirectories, defaults to '*'

    arguments: variadic, each must be a subdirectory of `root_dir`
    """
    files = []
    p = Path(root_dir)
    # each arg should be a subdirectory of root_dir
    for arg in args:
        subdir = p / arg
        if subdir.exists():
            # all .sh files in subdir in sorted order
            # essentially what `ls` does
            files.extend(sorted(list([q.as_posix() for q in subdir.glob(glob)])))
        else:
            print(f"subdirectory {subdir.name} does not exist")
            sys.exit(1)
    return files


def load_yaml_from_file(filename: str):
    p = Path(filename)
    if p.exists():
        with open(filename, "r") as f:
            return yaml.load(f)
    else:
        print(f"file not found: {p.name}")
        sys.exit(1)


def get_vars_from_files(files: Sequence[str]):
    """Takes a list of variable files
       in `root_dir` of increasing precedence, returns a merged dict

       keyword_arguments:
       root_dir -- directory from which to look for files
    """
    d = {}
    for file in files:
        y = load_yaml_from_file(file)
        if y:
            for k, v in y.items():
                d[k] = v
        else:
            print(f"Could not read yaml from {file}")
            sys.exit(1)
    return d


def exit_if_type_mismatch(variable, expected_type):
    if not isinstance(variable, expected_type):
        print(f"Expected variable to be {expected_type}, got {type(variable)}:")
        print(variable)
        sys.exit(1)


description = """Expects a jinja2 templated packer.yaml and the name of one or more builders.
Each builder must have a corresponding yaml file in `./builders`.
ex: builder gecko-1-miles-test has is configured at `./builders/gecko-1-miles-test.yaml`
Outputs a packer JSON template to stdout."""
parser = argparse.ArgumentParser(description=description)
parser.add_argument("packer_template", type=str, help="packer manifest to template")
parser.add_argument("builders", type=str, nargs="+", help="list of builders to build")
args = parser.parse_args()

packer_template = args.packer_template
builders = args.builders
builders_dir = "./builders"
var_files_dir = "./template/vars"
builder_template_dir = "./template/builders"
variables: Dict[str, Any] = {}
templated_builders: Sequence[Dict[str, str]] = []

for builder in builders:
    script_directories: Sequence[str] = []
    builder_template = ""

    builder_config_file = builders_dir + "/" + builder + ".yaml"
    builder_config = load_yaml_from_file(builder_config_file)

    # script_directories should be a list of yaml files in ./template/vars
    if "script_directories" in builder_config:
        script_directories = builder_config["script_directories"]
        exit_if_type_mismatch(script_directories, list)
    else:
        print(f"<warning> Missing `script_directories` key for builder {builder}")

    # var_files should be a list of yaml files in ./template/vars
    if "var_files" in builder_config:
        var_files = builder_config["var_files"]
        exit_if_type_mismatch(var_files, list)
        var_files = [Path(var_files_dir) / (file + ".yaml") for file in var_files]
        variables = get_vars_from_files(var_files)
    else:
        print(f"<warning> Missing `var_files` key for builder {builder}")

    # overwrites previously defined keys from var_files
    if "override_vars" in builder_config:
        override_vars = builder_config["override_vars"]
        exit_if_type_mismatch(override_vars, dict)
        for k, v in override_vars.items():
            variables[k] = v

    if "template" in builder_config:
        builder_template = builder_config["template"]
        exit_if_type_mismatch(builder_template, str)
    else:
        print(f"Missing `template` key for builder {builder}")
        sys.exit(1)

    templated_builders.append(
        {
            "name": builder,
            "template": builder_template,
            "scripts": get_files_from_subdirs(
                *script_directories, root_dir="./scripts", glob="*.sh"
            ),
        }
    )

# cannot be overriden
variables["builders"] = templated_builders

with open(packer_template, "r") as f:
    packer_template_str = f.read()
try:
    e = Environment(loader=FileSystemLoader([builder_template_dir]))
    t = e.from_string(packer_template_str)
    output = t.render(variables)
except TemplateNotFound as err:
    print(f"Template not found: {err.message}")
    sys.exit(1)
except TemplateSyntaxError as err:
    print(
        f"Error in template {packer_template}: line {err.lineno}, error: {err.message}"
    )
    sys.exit(1)
except TemplateError as err:
    print(f"Error for template {packer_template}, {err.message}")
    sys.exit(1)

# output needs to be valid yaml
data = yaml.load(output)
# convert to json for packer
print(json.dumps(data))
