#!/bin/bash

if [[ -z ${1} ]]; then
    echo "Usage: ./build.sh amd64"
    exit 1
fi

# `jq` is required to parse the VERSION.json file. Output of jq is used to set the build-args
#
# Example:
#
# jq -r 'to_entries[] | [(.key | ascii_upcase),.value] | join("=")' < VERSION.json
#
# Output:
#
# AMD64_URL=https://github.com/Sonarr/Sonarr/releases/download/v4.0.5.1710/Sonarr.main.4.0.5.1710.linux-musl-x64.tar.gz
# ARM64_URL=https://github.com/Sonarr/Sonarr/releases/download/v4.0.5.1710/Sonarr.main.4.0.5.1710.linux-musl-arm64.tar.gz
# DESCRIPTION=main/v4-stable
# LATEST=true
# SBRANCH=main
# TEST_AMD64=true
# TEST_ARM64=true
# TEST_URL=http://localhost:8989/system/status
# VERSION=4.0.5.1710

# To avoid permissions issues with shared volumes, use `--build-arg` to change the
# uid:gid of the image at build time. This will ensure that the image has the same
# uid:gid as the user running the build command.

UID=$(id -u)
GID=$(id -g)

org=qnimbus
image=$(basename $(pwd))
docker build --platform "linux/${1}" -f "./linux-${1}.Dockerfile" -t "${org}:${image}-${1}" --build-arg=UID=${UID} --build-arg=GID=${GID} $(for i in $(jq -r 'to_entries[] | [(.key | ascii_upcase),.value] | join("=")' < VERSION.json); do out+="--build-arg $i " ; done; echo $out;out="") .
