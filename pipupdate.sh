#! /bin/sh

export CUSTOM_COMPILE_COMMAND=./pipupdate.sh
python -m piptools compile --generate-hashes "${@}" --output-file requirements.txt
