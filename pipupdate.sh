#! /bin/sh

export CUSTOM_COMPILE_COMMAND=./pipupdate.sh
# See https://stackoverflow.com/questions/58843905/what-is-the-proper-way-to-decide-whether-to-allow-unsafe-package-versions-in-pip
# for an explanation of why we use --allow-unsafe option below
python -m piptools compile --generate-hashes "${@}" --allow-unsafe --output-file requirements.txt
