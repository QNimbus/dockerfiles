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
# DESCRIPTION=Alpine 3.20
# UPSTREAM_DIGEST_AMD64=sha256:dabf91b69c191a1a0a1628fd6bdd029c0c4018041c7f052870bb13c5a222ae76
# UPSTREAM_DIGEST_ARM64=sha256:647a509e17306d117943c7f91de542d7fb048133f59c72dff7893cffd1836e11
# UPSTREAM_IMAGE=alpine
# UPSTREAM_TAG=3.20
# VERSION=3.2.0.0
# VERSION_S6=3.2.0.0

org=qnimbus
image=$(basename $(pwd))
docker build --platform "linux/${1}" -f "./linux-${1}.Dockerfile" -t "${org}:${image}-${1}" $(for i in $(jq -r 'to_entries[] | [(.key | ascii_upcase),.value] | join("=")' < VERSION.json); do out+="--build-arg $i " ; done; echo $out;out="") .
