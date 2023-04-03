#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# see https://developer.nvidia.com/cudnn
# steps from https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html
#   alternate resource: https://gist.github.com/valgur/fcd72fcdf5db81a826f8ff9802621d75

# official steps

UBUNTU_RELEASE=$(lsb_release -rs) # 18.04
DISTRO=ubuntu${UBUNTU_RELEASE//\./} # ubuntu1804
cuda_version="cuda12.0"
cudnn_version="8.8.1.*"

wget https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/cuda-${DISTRO}.pin 

sudo mv cuda-${DISTRO}.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/ /"
sudo apt-get update

sudo apt-get install libcudnn8=${cudnn_version}-1+${cuda_version}
sudo apt-get install libcudnn8-dev=${cudnn_version}-1+${cuda_version}

# alternate steps

# # set up apt repo
# sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/3bf863cc.pub
# echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/${DISTRO}/x86_64 /" | sudo tee -a /etc/apt/sources.list.d/cuda.list

# # install
# sudo apt-get install -y libcudnn${CUDNN_VERSION}-dev