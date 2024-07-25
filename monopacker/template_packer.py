#!/usr/bin/env python3

import errno, os
import click
import sys
from pathlib import Path
from typing import Any, Dict, Sequence
from jinja2 import (
    Environment,
    FileSystemLoader,
    TemplateNotFound,
    TemplateError,
    TemplateSyntaxError,
)
import subprocess
from ruamel.yaml import YAML

from .filters import clean_gcp_image_name
from .secrets import pack_secrets, generate_packer_secret_chmod_shell
from .files import pack_files

yaml = YAML(typ="safe")


# TODO: move to a utils module
def get_short_git_commit(report_dirty=True):
    try:
        # Get the short SHA1 of the latest commit
        sha1 = (
            subprocess.check_output(["git", "rev-parse", "--short", "HEAD"])
            .strip()
            .decode("utf-8")
        )

        if report_dirty:
            # Check if there are any tracked changes in the working directory
            changes = (
                subprocess.check_output(["git", "status", "--porcelain"])
                .strip()
                .decode("utf-8")
            )
            tracked_changes = [
                line
                for line in changes.split("\n")
                if line and not line.startswith("??")
            ]
            if tracked_changes:
                sha1 += "-dirty"

        return sha1

    except subprocess.CalledProcessError as e:
        return str(e)


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


def merge_vars(base_vars, override_vars):
    """Takes two dicts, returns a new dict. Values in the second dict take precedence.

    If both dicts have a dictionary value for a key their subdicts are
    merged, recursively.  All other values (including lists) are overridden.
    """
    d = {**base_vars}
    for k, v in override_vars.items():
        # recursively merge dicts
        if k in base_vars and type(v) == type(base_vars[k]) and isinstance(v, dict):
            d[k] = merge_vars(base_vars[k], v)
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
                d = merge_vars(d, y)
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
            builder_vars = merge_vars(builder_vars, override_vars)

        # packer takes environment_vars as an array of "key=value" strings
        git_sha = get_short_git_commit()
        if "env_vars" in builder_vars:
            env_vars = builder_vars["env_vars"]
            exit_if_type_mismatch(env_vars, dict)
            env_vars = [f"{k}={v}" for k, v in env_vars.items()]
            builder_vars["env_vars"] = env_vars
            # inject monopacker builder name and monopacker git sha
            git_sha = get_short_git_commit()
            env_vars.append(f"MONOPACKER_BUILDER_NAME={builder}")
            env_vars.append(f"MONOPACKER_GIT_SHA={git_sha}")
        else:
            env_vars = [
                f"MONOPACKER_BUILDER_NAME={builder}",
                f"MONOPACKER_GIT_SHA={git_sha}",
            ]

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


def generate_packer_template_params(fn):
    "Decorate a click function with options for generate_packer_template"
    params = [
        click.argument("builders", nargs=-1, type=str, required=True),
        click.option(
            "--builders_dir",
            type=str,
            help="directory for builder configuration",
            default=os.environ.get("MONOPACKER_BUILDERS_DIR", "./builders"),
        ),
        click.option(
            "--var_files_dir",
            type=str,
            help="directory for builder var_files",
            default=os.environ.get("MONOPACKER_VARS_DIR", "./template/vars"),
        ),
        click.option(
            "--templates_dir",
            type=str,
            help="directory for builder templates",
            default=os.environ.get("MONOPACKER_TEMPLATES_DIR", "./template/builders"),
        ),
        click.option(
            "--scripts_dir",
            type=str,
            help="directory for builder templates",
            default=os.environ.get("MONOPACKER_SCRIPTS_DIR", "./scripts"),
        ),
        click.option(
            "--files_dir",
            type=str,
            help="directory for binary files used in packer provisioners",
            default=os.environ.get("MONOPACKER_FILES_DIR", "./files"),
        ),
        click.option(
            "--secrets_file",
            type=str,
            help="file containing secrets",
            default="./fake_secrets.yaml",
        ),
    ]
    params.reverse()
    for param in params:
        fn = param(fn)
    return fn


def generate_packer_template(
    *,
    builders,
    builders_dir,
    var_files_dir,
    templates_dir,
    scripts_dir,
    files_dir,
    secrets_file,
    **_,
):
    pack_secrets(secrets_file, "secrets.tar")
    pack_files(files_dir, "files.tar")

    # variables namespaced per builder
    variables: Dict[str, Dict[str, Any]] = {}

    templated_builders = get_builders_for_templating(
        builders,
        builders_dir=builders_dir,
        var_files_dir=var_files_dir,
        scripts_dir=scripts_dir,
    )

    # TODO: remove
    variables["builders"] = templated_builders
    linux_builders = variables["linux_builders"] = [
        builder["vars"]["name"]
        for builder in templated_builders
        if builder["platform"] == "linux"
    ]
    windows_builders = variables["windows_builders"] = [
        builder["vars"]["name"]
        for builder in templated_builders
        if builder["platform"] == "windows"
    ]

    pkr = {
        "builders": [],
        "provisioners": [],
        "post-processors": [],
    }

    # include some setup for linux and windows builders
    if linux_builders:
        pkr["provisioners"].append(
            {
                "type": "file",
                "source": "./files.tar",
                "destination": "/tmp/",
                # TODO: only
            }
        )
        pkr["provisioners"].append(
            {
                "type": "shell",
                "inline": [
                    # files.tar is two levels deep (/tmp/files)
                    "sudo tar xvf /tmp/files.tar -C / --strip-components=1",
                    "rm /tmp/files.tar",
                ],
                # TODO: only
            }
        )
        pkr["provisioners"].append(
            {
                "type": "file",
                "source": "./secrets.tar",
                "destination": "/tmp/",
                # TODO: only
            }
        )
        pkr["provisioners"].append(
            {
                "type": "shell",
                "inline": [
                    "sudo mkdir -p /etc/taskcluster/secrets",
                    "sudo tar xvf /tmp/secrets.tar -C /",
                    "sudo chown root:root -R /etc/taskcluster",
                    "sudo chmod 0400 -R /etc/taskcluster/secrets",
                    "rm /tmp/secrets.tar",
                ],
                "only": linux_builders,
            }
        )
        # chmod/chown all secret files (above only gets /etc/taskcluster)
        pkr["provisioners"].append(
            {
                "type": "shell",
                "inline": generate_packer_secret_chmod_shell(secrets_file),
                "only": linux_builders,
            }
        )
        pkr["provisioners"].append(
            {
                "type": "shell",
                "inline": [
                    "/usr/bin/cloud-init status --wait",
                ],
                "only": linux_builders,
            }
        )

    e = Environment(loader=FileSystemLoader([templates_dir]))
    e.filters["clean_gcp_image_name"] = clean_gcp_image_name
    for builder in templated_builders:

        # for each monopacker builder, use the Jinja template to generate a Packer builder
        template_file = Path(templates_dir) / (builder["template"] + ".jinja2")
        with open(template_file) as f:
            template_str = f.read()
        try:
            t = e.from_string(template_str)
            variables = {
                "builder": {
                    "vars": builder["vars"],
                }
            }
            output = t.render(variables)
        except TemplateNotFound as err:
            print(f"Template not found: {err.message}")
            sys.exit(1)
        except TemplateSyntaxError as err:
            print(
                f"Error in template {template_file}: line {err.lineno}, error: {err.message}"
            )
            sys.exit(1)
        except TemplateError as err:
            print(f"Error for template {template_file}, {err.message}")
            sys.exit(1)

        try:
            template_builders = yaml.load(output)
        except Exception as e:
            print(f"Template {template_file} generated invalid YAML:\n{output}\n")
            print(f"variables:\n{variables}\n")
            print(f"Got exception: {e}")
            sys.exit(1)

        if type(template_builders) != list:
            print(
                f"Template {template_file} generated YAML that is not an array:\n{output}\n"
            )
            print(f"Packer template variables:\n{variables}\n")
            sys.exit(1)

        pkr["builders"].extend(template_builders)

        # make a provisioner for each builder, specialized to run only on that builder,
        # with that builder's scripts and variables
        if linux_builders:
            previous_script = ""
            # sbom_step_present = False
            for script in builder["scripts"]:
                # detect if previous script was a reboot (via name)
                # - if it was, add a pause before running the next step
                pause_before = "0s"
                if "reboot" in previous_script:
                    pause_before = "10s"
                pkr["provisioners"].append(
                    {
                        "type": "shell",
                        "scripts": script,
                        "pause_before": pause_before,
                        "environment_vars": (
                            builder["vars"]["env_vars"]
                            if "env_vars" in builder["vars"]
                            else None
                        ),
                        "execute_command": (
                            builder["vars"]["execute_command"]
                            if "execute_command" in builder["vars"]
                            else None
                        ),
                        "expect_disconnect": True,
                        "start_retry_timeout": (
                            builder["vars"]["ssh_timeout"]
                            if "ssh_timeout" in builder["vars"]
                            else None
                        ),
                        "only": (
                            [builder["vars"]["name"]]
                            if builder["platform"] == "linux"
                            else []
                        ),
                    }
                )
                # add a step that copies the SBOM to the localhost
                # using a file provisioner.
                # if "sbom" in script:
                #     sbom_step_present = True
                #     pkr["provisioners"].append(
                #         {
                #             "type": "file",
                #             "direction": "download",
                #             "source": "/etc/SBOM.md",
                #             # will be copied to SBOMs/image_name.md in post-processor
                #             "destination": "SBOMs/temp_sbom.md",
                #         }
                #     )
                previous_script = script

        if windows_builders:
            pkr["provisioners"].append(
                {
                    "type": "powershell",
                    "scripts": builder["scripts"],
                    "only": (
                        [builder["vars"]["name"]]
                        if builder["platform"] == "windows"
                        else []
                    ),
                }
            )

    # ensure we output the expected artifacts..
    pkr["post-processors"] = [
        {"type": "manifest", "output": "packer-artifacts.json", "strip_path": True},
    ]

    # v1: detects if sbom step present and adds a post-processor to move the sbom
    # if a sbom was generated, copy it from the temp path to the final path
    # if sbom_step_present:
    #     pkr["post-processors"].append(
    #         {
    #             "type": "shell-local",
    #             "script": "monopacker/post-processors/move_sbom_to_latest_artifact_name.py",
    #             # TODO: add 'only'?
    #         }
    #     )

    # v2: checks env var to see if we should generate SBOMs
    # if env has monopacker_generate_sboms=true, generate SBOMs
    if 'monopacker_generate_sbom' in builder["vars"]:
        if builder["vars"]['monopacker_generate_sbom']:
            remote_temp_path_for_sbom_tool = "/tmp/monopacker_sbom_script"
            # TODO: allow configuring where the SBOM is stored on the remote host

            # see if optional params are present
            sbom_tool_args = ""
            if 'monopacker_sbom_command_args' in builder["vars"]:
                sbom_tool_args = builder["vars"]['monopacker_sbom_command_args']
            sbom_tool = "monopacker_ubuntu_sbom.py"
            if 'monoopacker_sbom_script' in builder["vars"]:
                sbom_tool = builder["vars"]['monopacker_sbom_script']

            # build path relative to module's root based on
            module_root_dir = Path(__file__).parent
            full_path_to_sbom_tool = module_root_dir / 'utils' / sbom_tool
            
            # comments not working, wait for HCL migration
            # pkr["provisioners"].append(
            #     {
            #       "//": "SBOM generation process: start",
            #     }
            # )
            # copy script over to temp path
            pkr["provisioners"].append(
                {
                    "type": "file",
                    "direction": "upload",
                    "source": str(full_path_to_sbom_tool),
                    "destination": remote_temp_path_for_sbom_tool,
                }
            )
            # chmod the script, run the sbom tool, and remove script from temp path
            pkr["provisioners"].append(
                {
                    "type": "shell",
                    "inline": [
                        f"chmod +x {remote_temp_path_for_sbom_tool}",
                        "cd /etc",
                        f"sudo {remote_temp_path_for_sbom_tool} {sbom_tool_args}",
                        f"rm {remote_temp_path_for_sbom_tool}",
                    ],
                    "environment_vars": builder['vars']['env_vars'],
                    # TODO: add only?
                }
            )
            # copy SBOM back to localhost
            pkr["provisioners"].append(
                {
                    "type": "file",
                    "direction": "download",
                    "source": "/etc/SBOM.md",
                    # will be copied to SBOMs/image_name.md in post-processor
                    "destination": "SBOMs/temp_sbom.md",
                }
            )
            # add post-processor that renames the SBOM to the artifact name
            pkr["post-processors"].append(
                {
                    "type": "shell-local",
                    "script": "monopacker/post-processors/move_sbom_to_latest_artifact_name.py",
                    # TODO: add 'only'?
                }
            )
            # pkr["provisioners"].append(
            #     {
            #       "//": "SBOM generation process: finish",
            #     }
            # )

    return pkr
