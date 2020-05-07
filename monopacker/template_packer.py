#!/usr/bin/env python3

import errno, os
from pathlib import Path
from typing import Any, Dict, Sequence

from ruamel.yaml import YAML

from . import monorepo

yaml = YAML(typ="safe")

def get_files_from_subdirs(*args, root_dir=".", globs=["*"]):
    """Get an sorted list of files from a list of subdirectories

    keyword arguments:
    root_dir -- root directory in which to look for subdirectories, defaults to '.'
    globs -- list of glob expressions for files in subdirectories, defaults to ['*']

    arguments: variadic, each must be a subdirectory of `root_dir`
    """
    files = []
    p = Path(root_dir)
    # each arg should be a subdirectory of root_dir
    for arg in args:
        subdir = p / arg
        if subdir.exists():
            # all files matching globs in subdir in sorted order
            # essentially what `ls` does
            globbed_files = [item for glob in globs for item in subdir.glob(glob)]
            files.extend(sorted(list([q.as_posix() for q in globbed_files])))
        else:
            print(f"subdirectory {subdir.name} does not exist")
            raise FileNotFoundError(
                errno.ENOENT, os.strerror(errno.ENOENT), subdir.name
            )
    return files


def load_yaml_from_file(filename: str):
    p = Path(filename)
    if p.exists():
        with open(filename, "r") as f:
            return yaml.load(f)
    else:
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), filename)


def handle_vars(base_vars, override_vars):
    """Takes two dicts, returns a new dict. Values in the second dict take precedence.

       If both dicts have a dictionary value for a key their subdicts are merged
    """
    d = {**base_vars}
    for k, v in override_vars.items():
        # merge dicts
        if k in base_vars and type(v) == type(base_vars[k]) and isinstance(v, dict):
            d[k] = {**base_vars[k], **v}
        else:
            d[k] = v
    return d


def get_vars_from_files(files: Sequence[str]):
    """Takes a list of variable files
       in `root_dir` of increasing precedence, returns a merged dict
    """
    d = {}
    for file in files:
        try:
            y = load_yaml_from_file(file)
            if y:
                d = handle_vars(d, y)
        except Exception as e:
            print(f"Could not read yaml from {file}")
            raise e
    return d


def exit_if_type_mismatch(variable, expected_type):
    if not isinstance(variable, expected_type):
        print(f"Expected variable to be {expected_type}, got {type(variable)}:")
        print(variable)
        sys.exit(1)


def get_builders_for_templating(
    names: Sequence[str], builders_dir, var_files_dir, scripts_dir
):
    """Takes a list of builder names and builds dicts for templating

    keyword arguments:
    builders_dir -- directory in which to look for builders
    var_files_dir -- directory in which to look for builder variable files
    scripts_dir -- directory in which to look for script directories
    """
    builders: Sequence[Dict[str, str]] = []
    for builder in names:
        script_directories: Sequence[str] = []
        builder_template = ""
        builder_vars: Dict[str, Any] = {}

        builder_config_file = Path(builders_dir) / (builder + ".yaml")
        builder_config = load_yaml_from_file(builder_config_file)

        # script_directories should be a list directories in ./scripts
        if "script_directories" in builder_config:
            script_directories = builder_config["script_directories"]
            exit_if_type_mismatch(script_directories, list)
        else:
            print(f"<warning> Missing `script_directories` key for builder {builder}")

        # builder_var_files should be a list of yaml files in ./template/vars
        if "builder_var_files" in builder_config:
            builder_var_files = builder_config["builder_var_files"]
            exit_if_type_mismatch(builder_var_files, list)
            builder_var_files = [
                Path(var_files_dir) / (file + ".yaml") for file in builder_var_files
            ]
            builder_vars = get_vars_from_files(builder_var_files)
        else:
            print(f"<warning> Missing `builder_var_files` key for builder {builder}")

        # overwrites previously defined keys from builder_var_files
        if "builder_vars" in builder_config:
            override_vars = builder_config["builder_vars"]
            exit_if_type_mismatch(override_vars, dict)
            builder_vars = handle_vars(builder_vars, override_vars)

        # packer takes environment_vars as an array of "key=value" strings
        if "env_vars" in builder_vars:
            env_vars = builder_vars["env_vars"]
            exit_if_type_mismatch(env_vars, dict)
            env_vars = [f"{k}={v}" for k, v in env_vars.items()]
            builder_vars["env_vars"] = env_vars
            builder_vars["env_vars"].append(f"TASKCLUSTER_VERSION={monorepo.version}")

        if "template" in builder_config:
            builder_template = builder_config["template"]
            exit_if_type_mismatch(builder_template, str)
        else:
            print(f"Missing `template` key for builder {builder}")
            sys.exit(1)

        if "platform" in builder_config:
            builder_platform = builder_config["platform"]
            exit_if_type_mismatch(builder_template, str)
        else:
            print(f"Missing `platform` key for builder {builder}")
            sys.exit(1)

        # each builder has its own pseudo namespace
        # for variables, scripts, files, template, etc.
        builders.append(
            {
                "template": builder_template,
                # name is special
                "vars": {**builder_vars, "name": builder},
                "scripts": get_files_from_subdirs(
                    *script_directories, root_dir=scripts_dir, globs=["*.sh", "*.ps1"]
                ),
                "platform": builder_platform,
            }
        )
    return builders

