#!/usr/bin/env python3

import sys
import ruamel.yaml, json

yaml = ruamel.yaml.YAML(typ="safe")
print(json.dumps(yaml.load(sys.stdin.read())))
