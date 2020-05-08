import os, sys, argparse, json
from typing import Any, Dict
import click

from monopacker.template_packer import generate_packer_template

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
    data = generate_packer_template(**kwargs)
    print(json.dumps(data))
