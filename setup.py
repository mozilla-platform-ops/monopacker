#!/usr/bin/env python

from setuptools import setup

setup(
    name='monopacker',
    version='0.1.0',
    author='taskcluster team',
    author_email='tools-taskcluster@lists.mozilla.org',
    description='Packer wrapper with templating features',
    scripts=['bin/monopacker'],
    url='https://github.com/taskcluster/monopacker',
    packages=['monopacker', 'tests'],
    package_dir={'monopacker': 'monopacker'},
    install_requires=[
        'jinja2>=2.0',
        'ruamel.yaml>=0.16',
        'click~=7.0',
    ],
    include_package_data=True,
    license='MPLv2',
    zip_safe=False,
    keywords='packer templating',
)
