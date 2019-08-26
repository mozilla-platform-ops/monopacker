#!/usr/bin/env python3

import os, sys, tarfile, tempfile
from pathlib import Path

from ruamel.yaml import YAML

yaml = YAML(typ="safe")

outfile = "secrets.tar"

if len(sys.argv) < 2:
    print(
        f"""Usage: {sys.argv[0]} <yaml input filename> [output tar filename]
{sys.argv[0]} expects a path to a file of the form:
- name: foo
  path: /path/to/foo
  value: what
- name: bar
  path: /path/to/bar
  value: yeah
{sys.argv[0]} outputs a tar archive, the name of which can be optionally supplied.
"""
    )
    sys.exit(1)

# third optional argument
# is output filename
if 2 < len(sys.argv):
    outfile = sys.argv[2]

with open(sys.argv[1], "r") as f:
    secrets = yaml.load(f)

    # create a directory structure as defined
    # by the secrets yaml file
    with tarfile.open(outfile, "w") as tar:
        with tempfile.TemporaryDirectory() as d:
            for secret in secrets:
                # name is optional
                if "name" not in secret:
                    name = "unnamed"
                if "path" not in secret:
                    print(f"Encountered secret {name} without `path` key, exiting.")
                if "value" not in secret:
                    print(f"Encountered secret {name} without `value` key, exiting.")
                path = Path(d + secret["path"])
                os.makedirs(path.parent, exist_ok=True)
                with open(path, "w") as secret_file:
                    secret_file.write(secret["value"])
                tar.add(path, arcname=secret["path"])
