#!/bin/bash
#
# This is a script to build the TumorSynth container
#
# If you don't have space run this command: docker builder prune -a
# 
# Define version
version='v1.0'

# Get directory of this script
docker_dir=`dirname $0`

# Build docker with version in tag
tag="tumorsynth-${version}"
PATH=$PATH:/sbin
PATH=$PATH:/usr/sbin

docker build --build-arg version_arg=${version} --tag=${tag} -f `pwd`/Dockerfile `pwd`
echo ${tag}
