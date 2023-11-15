import sys
import click
import os
import subprocess
import json
import shlex


def run_packer_params(fn):
    "Decorate a click function with options for run_packer"
    params = [
        click.option(
            "--packer", type=str, help="path to the packer binary", default="packer"
        ),
        click.option(
            "--packer-args",
            type=str,
            help="additional arguments to pass to packer (shell-quoted)",
            default="",
        ),
    ]
    params.reverse()
    for param in params:
        fn = param(fn)
    return fn


def run_packer(command, input, *, packer, packer_args, **_):
    """Run packer with the given (JSON) template, passing additional extra_args"""
    packer_args = shlex.split(packer_args)
    try:
        subprocess.run(
            [packer, command] + packer_args + ["-"],
            input=bytes(json.dumps(input), "utf8"),
            check=True,
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"packer exited with code {e.returncode}", file=sys.stderr)
        sys.exit(1)
