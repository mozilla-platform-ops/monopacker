import os, sys, argparse, json
from typing import Any, Dict
import click

from monopacker.packer import (
    run_packer,
    run_packer_params,
)
from monopacker.template_packer import (
    generate_packer_template,
    generate_packer_template_params,
)

@click.group()
def main():
    """
    Manages building worker images for Taskcluster.
    """

@main.command(name='packer-template')
@generate_packer_template_params
def packer_template(**kwargs):
    """This tool expects a jinja2 templated packer.yaml and the name of one or more builders.
    Each builder must have a corresponding yaml file in `./builders`.
    ex: builder docker_worker_aws is configured at `./builders/docker_worker_aws.yaml`
    Outputs a packer JSON template to stdout."""
    packer_template = generate_packer_template(**kwargs)
    print(json.dumps(packer_template, sort_keys=True, indent=4))

@main.command(name='validate')
@generate_packer_template_params
@run_packer_params
def validate(**kwargs):
    """Validate the generated template with 'packer validate'"""
    packer_template = generate_packer_template(**kwargs)
    run_packer('validate', packer_template, **kwargs)

@main.command(name='build')
@generate_packer_template_params
@run_packer_params
def validate(**kwargs):
    """Validate the generated template with 'packer validate'"""
    packer_template = generate_packer_template(**kwargs)
    run_packer('build', packer_template, **kwargs)
