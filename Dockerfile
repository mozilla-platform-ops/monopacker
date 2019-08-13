FROM ubuntu

LABEL maintainer="miles@milescrabilll.com"

ENV GOPATH=/go
RUN mkdir ${GOPATH}
ENV PATH=${PATH}:${GOPATH}/bin:/usr/local/bin

# prevents interactive installation
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# needed for add-apt-repository
RUN apt update && \
    apt install -y software-properties-common

# ppa for go
RUN add-apt-repository -y ppa:longsleep/golang-backports

RUN apt update && \
    apt install -y build-essential git && \
    apt install -y vagrant virtualbox && \
    apt install -y python3-pip && \
    apt install -y curl git jq && \
    apt install -y golang-go

RUN pip3 install pyyaml yq

# we need a fixed version of packer
# RUN go get -u github.com/hashicorp/packer
RUN go get -u github.com/hashicorp/packer && \
    cd ${GOPATH}/src/github.com/hashicorp/packer && \
    git remote add milescrabill https://github.com/milescrabill/packer.git && \
    git fetch milescrabill && \
    git checkout fix-vagrant-builder-basebox-sourcebox && \
    go install .

WORKDIR /monopacker
CMD make validate
