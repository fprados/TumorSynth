#!/bin/bash

working_dir=`pwd`

mkdir -p tmp
docker run --rm \
		 	-it \
    		-v ${working_dir}:/data \
			-v ${working_dir}/tmp:/tmp \
			--platform=linux/amd64 \
			tumorsynth-v1.0 \
			bash
rm -rf tmp