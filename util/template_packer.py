#!/usr/bin/env python3

import sys, argparse, yaml
from jinja2 import (
    Environment,
    FileSystemLoader,
    TemplateNotFound,
    TemplateError,
    TemplateSyntaxError,
)
from pathlib import Path
from typing import Any, Dict, Sequence


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
            files.extend(sorted(list([q.name for q in subdir.glob(glob)])))
        else:
            print(f"subdirectory {subdir.name} does not exist")
            sys.exit(1)
    return files


def load_yaml_from_file(filename: str):
    p = Path(filename)
    if p.exists():
        with open(filename, "r") as f:
            return yaml.safe_load(f)
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


if len(sys.argv) < 3:
    print(
        f"""Usage: {sys.argv[0]} <jinja2 template> <worker_type> [worker_type...]
{sys.argv[0]} expects a jinja2 templated packer.yaml and the name of one or more worker_types
              each worker_type must have a corresponding yaml file in `./worker_types`
              ex: worker_type gecko-1-miles-test has is configured at `./worker_types/gecko-1-miles-test.yaml`
{sys.argv[0]} outputs a packer JSON template to stdout
"""
    )
    sys.exit(1)

description = "templates packer"
parser = argparse.ArgumentParser(description)
parser.add_argument("packer_template", type=str, help="source packer template")
parser.add_argument("worker_types", type=str, nargs="+", help="worker_type to build")
args = parser.parse_args()

packer_template = args.packer_template
worker_types = args.worker_types
worker_types_dir = "./worker_types"
var_files_dir = "./template/vars"
builder_template_dir = "./template/builders"
variables: Dict[str, Any] = {}
builders: Sequence[Dict[str, str]] = []

for worker_type in worker_types:
    script_directories: Sequence[str] = []
    builder_template = ""

    worker_type_config_file = worker_types_dir + "/" + worker_type + ".yaml"
    worker_type_config = load_yaml_from_file(worker_type_config_file)

    # script_directories should be a list of yaml files in ./template/vars
    if "script_directories" in worker_type_config:
        script_directories = worker_type_config["script_directories"]
        exit_if_type_mismatch(script_directories, list)

    # var_files should be a list of yaml files in ./template/vars
    if "var_files" in worker_type_config:
        var_files = worker_type_config["var_files"]
        exit_if_type_mismatch(var_files, list)
        var_files = [Path(var_files_dir) / (file + ".yaml") for file in var_files]
        variables = get_vars_from_files(var_files)

    # overwrites previously defined keys from var_files
    if "override_vars" in worker_type_config:
        override_vars = worker_type_config["override_vars"]
        exit_if_type_mismatch(override_vars, dict)
        for k, v in override_vars.items():
            variables[k] = v

    if "template" in worker_type_config:
        builder_template = worker_type_config["template"]
        exit_if_type_mismatch(builder_template, str)

    builders.append(
        {
            "name": worker_type,
            "template": builder_template if builder_template else worker_type,
            "scripts": get_files_from_subdirs(
                *script_directories, root_dir="./scripts", glob="*.sh"
            ),
        }
    )

# cannot be overriden
variables["builders"] = builders

with open(packer_template, "r") as f:
    packer_template_str = f.read()

try:
    e = Environment(loader=FileSystemLoader([builder_template_dir]))
    t = e.from_string(packer_template_str)
    print(t.render(variables))
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

