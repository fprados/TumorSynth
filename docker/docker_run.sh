#!/bin/bash

working_dir=`pwd`

mkdir tmp
docker run --rm \
		 	-it \
    		-v ${working_dir}/../data:/data \
			-v ${working_dir}/tmp:/tmp \
			tumorsynth-v1.0 \
			bash
rm -rf tmp