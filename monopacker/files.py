#!/usr/bin/env python3

import os, sys, tarfile, tempfile
from pathlib import Path

def pack_files(files_dir, files_tar):
    # create a directory with `files` as the top level directory component.
    with tarfile.open(files_tar, "w") as tar:
        tar.add(files_dir, arcname='files')
