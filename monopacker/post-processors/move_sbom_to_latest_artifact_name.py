#!/usr/bin/env python3

import json
import sys
import argparse
import os
import shutil

# Set up argparse
parser = argparse.ArgumentParser(description="Move temp_sbom.md to the last build's artifact name.md")
parser.add_argument('-d', '--debug', action='store_true', help='Print what would have happened instead of performing the move')
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

# Handle the move operation or describe the action if in debug mode
if matching_build:
    name = matching_build['name']
    artifact_id = matching_build['artifact_id']
    source_path = 'SBOMs/temp_sbom.md'
    destination_dir = f'SBOMs/{name}'
    destination_path = f'{destination_dir}/{artifact_id}.md'
    
    if not os.path.exists(source_path):
        print(f'File {source_path} not found.')
        sys.exit(0)

    if args.debug:
        print(f'Would move {source_path} to {destination_path}')
    else:
        try:
            # Create the destination directory if it doesn't exist
            os.makedirs(destination_dir, exist_ok=True)
            # Move the file
            shutil.move(source_path, destination_path)
            print(f'Moved {source_path} to {destination_path}')
        except Exception as e:
            print(f'An error occurred: {e}')
            sys.exit(1)
else:
    print('No matching build found.')
    sys.exit(1)