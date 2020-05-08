import os, sys, argparse, json
from typing import Any, Dict
import click

from jinja2 import (
    Environment,
    FileSystemLoader,
    TemplateNotFound,
    TemplateError,
    TemplateSyntaxError,
)

from monopacker.filters import clean_gcp_image_name
from monopacker.template_packer import *

@click.group()
def main():
    """
    Manages building worker images for Taskcluster.
    """

@main.command(name='packer-template')
@click.argument(
    'packer_template',
    type=str,
    ) #help="packer manifest to template")
@click.argument(
    'builders',
    nargs=-1,
    type=str,
    ) #help="list of builders to build")
@click.option(
    "--builders_dir",
    type=str,
    help="directory for builder configuration",
    default=os.environ.get("MONOPACKER_BUILDERS_DIR", "./builders"))
@click.option(
    "--var_files_dir",
    type=str,
    help="directory for builder var_files",
    default=os.environ.get("MONOPACKER_VARS_DIR", "./template/vars"))
@click.option(
    "--templates_dir",
    type=str,
    help="directory for builder templates",
    default=os.environ.get("MONOPACKER_TEMPLATES_DIR", "./template/builders"))
@click.option(
    "--scripts_dir",
    type=str,
    help="directory for builder templates",
    default=os.environ.get("MONOPACKER_SCRIPTS_DIR", "./scripts"))
def packer_template(**kwargs):
    """This tool expects a jinja2 templated packer.yaml and the name of one or more builders.
    Each builder must have a corresponding yaml file in `./builders`.
    ex: builder docker_worker_aws is configured at `./builders/docker_worker_aws.yaml`
    Outputs a packer JSON template to stdout."""
    packer_template = kwargs['packer_template']
    builders = kwargs['builders']
    builders_dir = kwargs['builders_dir']
    builder_var_files_dir = kwargs['var_files_dir']
    builder_templates_dir = kwargs['templates_dir']
    builder_scripts_dir = kwargs['scripts_dir']

    # variables namespaced per builder
    variables: Dict[str, Dict[str, Any]] = {}

    templated_builders = get_builders_for_templating(
        builders,
        builders_dir=builders_dir,
        var_files_dir=builder_var_files_dir,
        scripts_dir=builder_scripts_dir,
    )

    variables["builders"] = templated_builders
    variables["linux_builders"] = [
        builder["vars"]["name"]
        for builder in templated_builders
        if builder["platform"] == "linux"
    ]
    variables["windows_builders"] = [
        builder["vars"]["name"]
        for builder in templated_builders
        if builder["platform"] == "windows"
    ]

    with open(packer_template, "r") as f:
        packer_template_str = f.read()
    try:
        e = Environment(loader=FileSystemLoader([builder_templates_dir]))
        e.filters["clean_gcp_image_name"] = clean_gcp_image_name
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
    try:
        data = yaml.load(output)
    except Exception as e:
        print(f"Generated invalid YAML:\n{output}\n")
        print(f"Packer template variables:\n{variables}\n")
        print(f"Got exception: {e}")
        sys.exit(1)
    # convert to json for packer
    print(json.dumps(data))
