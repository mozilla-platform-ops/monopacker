#!/usr/bin/env python

from setuptools import setup

setup(
    name="monopacker",
    version="0.1.0",
    description="Packer wrapper with templating features",
    author="taskcluster team",
    author_email="tools-taskcluster@lists.mozilla.org",
    url="https://github.com/taskcluster/monopacker",
    packages=["monopacker"],
    package_dir={"monopacker": "monopacker"},
    include_package_data=True,
    license="MPLv2",
    zip_safe=False,
    keywords="packer templating",
)
