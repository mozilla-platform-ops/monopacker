#!/usr/bin/env python3

import os, sys, tarfile, tempfile
from pathlib import Path

from ruamel.yaml import YAML

yaml = YAML(typ="safe")

def pack_secrets(secrets_file, secrets_tar):
    with open(secrets_file, "r") as f:
        secrets = yaml.load(f)

        # create a directory structure as defined
        # by the secrets yaml file
        with tarfile.open(secrets_tar, "w") as tar:
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
