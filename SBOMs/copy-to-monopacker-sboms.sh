#!/usr/bin/env bash

# set -x
set -e

# Get the directory where the script is located
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the destination path relative to the script directory
DEST_DIR="$SCRIPTDIR/../../monopacker-sboms/"
DEST_DIR="$(realpath $DEST_DIR)"

# Rsync command with additional excludes
rsync -av \
  --exclude=".gitignore" \
  --exclude="*.sh" \
  --exclude="old/" \
  --exclude="*monopacker-testing*" \
  --exclude="temp_sbom.md" \
  --exclude="SBOM.md" \
  --exclude="README.md" \
  "$SCRIPTDIR/" "$DEST_DIR"

# Explanation:
# -a: archive mode (preserves symbolic links, file permissions, user & group ownerships, and timestamps)
# -v: verbose output
# --exclude: to exclude specific files or directories

# here doc for ascii art
cat << "EOF"
                                 
 ## ## ##  ###  ###  ###  ##  ## 
##  ## #  ## # ## # ## # ##  ##  
### ## #  ##   ##   #### ### ### 
 ## ## #  ## # ## # ##    ##  ## 
###  ###   ###  ###  ### ### ### 
                                 
EOF

# provide directions on how to commit the sboms
cat <<EOF
Please run the following to commit the copied SBOMs. 

  cd $DEST_DIR
  git st
  # inspect and ensure the changes are correct

  git add .
  git commit -m "adding new SBOMs"
  git push

EOF