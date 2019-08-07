#!/bin/bash

set -exv

# Do one final package cleanup, just in case.
apt-get autoremove -y
