#!/usr/bin/env python3

import json
import sys
import argparse
import os
import shutil

# Set up argparse
parser = argparse.ArgumentParser(description="Move temp_sbom.md to the last build's artifact name.md")
parser.add_argument('-m', '--move', action='store_true', help='Move the SBOM file using the latest build\'s artifact_id')
args = parser.parse_args()

# Load the JSON data from the file in the current working directory
file_path = 'packer-artifacts.json'
with open(file_path, 'r') as file:
    data = json.load(file)

# Extract the last_run_uuid
last_run_uuid = data['last_run_uuid']

# Find the matching build in the builds array
matching_build = None
for build in data['builds']:
    if build['packer_run_uuid'] == last_run_uuid:
        matching_build = build
        break

# Handle the move operation if specified, or describe the action if not specified
if matching_build:
    artifact_id = matching_build['artifact_id']
    source_path = 'SBOMs/temp_sbom.md'
    destination_path = f'SBOMs/{artifact_id}.md'
    
    if args.move:
        try:
            shutil.move(source_path, destination_path)
            print(f'Moved {source_path} to {destination_path}')
        except FileNotFoundError:
            print(f'File {source_path} not found.')
            sys.exit(1)
        except Exception as e:
            print(f'An error occurred: {e}')
            sys.exit(1)
    else:
        print(f'Would move {source_path} to {destination_path}')
else:
    sys.exit(1)