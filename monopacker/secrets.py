#!/usr/bin/env python3

import io
import tarfile

from ruamel.yaml import YAML

yaml = YAML(typ="safe")

def pack_secrets(secrets_file, secrets_tar):
    with open(secrets_file, "r") as f:
        secrets = yaml.load(f)

        # create a directory structure as defined
        # by the secrets yaml file
        with tarfile.open(secrets_tar, "w") as tar:
            for secret in secrets:
                # name is optional
                if "name" not in secret:
                    name = "unnamed"
                if "path" not in secret:
                    raise RuntimeError(f"Encountered secret {name} without `path` key")
                if "value" not in secret:
                    raise RuntimeError(f"Encountered secret {name} without `value` key")
                path = secret["path"].lstrip('/')
                value = bytes(secret["value"], "utf8")
                ti = tarfile.TarInfo(path)
                ti.size = len(value)
                tar.addfile(ti, io.BytesIO(value))

def generate_packer_secret_chmod_shell(secrets_file):
    command_arr = []
    with open(secrets_file, "r") as f:
        secrets = yaml.load(f)
        for secret in secrets:
            command_arr.append(f"sudo chown -R root:root `dirname {secret['path']}`")
            command_arr.append(f"sudo chmod -R 0400 `dirname {secret['path']}`")

    return command_arr