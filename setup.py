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
        'jinja2==2.11.3',
        'ruamel.yaml==0.16.10',
        'click==7.0',
    ],
    setup_requires=["pytest-runner"],
    tests_require=["pytest", "pyfakefs"],
    include_package_data=True,
    license='MPLv2',
    zip_safe=False,
    keywords='packer templating',
)
