FROM ubuntu:22.04

#
#   This is a docker containter for building FreeSurfer with TumorSynth.
#   To build it use the following command:
#      docker build --tag=TumorSynth-v1.0 -f `pwd`/DockerFile `pwd`
#
#   To execute it, please use the following command:
#       docker run --rm -it \
#		      -v `pwd`:/data \
#		      TumorSynth-v1.0 \
#		      mri_tumorsynth.sh  \
#             --i t1ce.nii.gz \
#             --o output.nii.gz \
#             --wholetumor
#   
#   More info at: https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth
#

# Add version from build arguments
ARG version_arg=""
ENV VERSION=$version_arg

# Add proxies from build arguments
ARG proxy_arg=""
ENV http_proxy=${proxy_arg}
ENV https_proxy=${proxy_arg}

# Setup timezone
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# We make some directories that we will need
RUN mkdir -p /opt && \
    mkdir -p /opt/weights && \
    mkdir -p /data  

# Install some packages
RUN apt-get -y update
RUN apt-get install -y --fix-missing \
      cmake \
      gcc \
      g++ \
      git \
      libpng-dev \
      openssl \
      libssl-dev \
      doxygen \
      curl \
      wget \
      apt-transport-https \
      ca-certificates \
      libcurl3-gnutls \
      software-properties-common \
      unzip 

# We copy the version of FreeSurfer that we want to build into the container
COPY extra-data/freesurfer-linux-ubuntu22_x86_64-7-dev.tar.gz /opt

# We extract the FreeSurfer source code
RUN tar -xzf /opt/freesurfer-linux-ubuntu22_x86_64-7-dev.tar.gz -C /opt && \
    rm /opt/freesurfer-linux-ubuntu22_x86_64-7-dev.tar.gz

# We set the FREESURFER_HOME environment variable to point to the FreeSurfer source code
ENV FREESURFER_HOME=/opt/freesurfer

# We set the SUBJECTS_DIR environment variable to point to the data directory
ENV SUBJECTS_DIR=/data

# We set the FS_LICENSE environment variable to point to the FreeSurfer license file
ENV FS_LICENSE=/opt/freesurfer/subjects/license.txt

# We set the PATH environment variable to include the FreeSurfer binaries
ENV PATH=$FREESURFER_HOME/bin:$PATH

# We set the LD_LIBRARY_PATH environment variable to include the FreeSurfer libraries
ENV LD_LIBRARY_PATH=$FREESURFER_HOME/lib:$LD_LIBRARY_PATH

 # Install some more packages for FSL
RUN apt-get -y update
RUN apt-get install -y --fix-missing \
      python3 \
      python3-pip \
      python3-venv \
      bzip2 \
      file \
      dc \
      mesa-utils \
      pulseaudio \
      libquadmath0 \
      libgtk2.0-0  \
      libgomp1 \
      bc

# We install FSL 6.0 from the official FSL website, which is the version of FSL that we want to use for TumorSynth
ENV FSLDIR="/usr/local/fsl"
RUN curl -Ls https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/getfsl.sh | sh -s

# Setting up FSL environment variables
ENV PATH=${FSLDIR}/share/fsl/bin:${PATH}
ENV FSLOUTPUTTYPE="NIFTI_GZ"
RUN . ${FSLDIR}/etc/fslconf/fsl.sh

# Setting up FreeSurfer environment variables
RUN /opt/freesurfer/SetUpFreeSurfer.sh 

# Download and install python 3.9
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_25.9.1-3-Linux-x86_64.sh && \
    sh Miniconda3-py39_25.9.1-3-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-py39_25.9.1-3-Linux-x86_64.sh

# We copy the weights for TumorSynth into the container
COPY extra-data/TumorSynth_v1.0.zip /opt/weights
COPY extra-data/Task003_InnerTumor.zip /opt/weights

# We extract the weights for TumorSynth
RUN unzip /opt/weights/TumorSynth_v1.0.zip -d /opt/weights && \
    mv /opt/weights/TumorSynth_v1.0 /opt/weights/Task002_Tumor && \
    unzip /opt/weights/Task003_InnerTumor.zip -d /opt/weights 

# We remove the folders and files that are not needed anymore to save space
RUN rm -rf /opt/weights/TumorSynth_v1.0 && \
    rm -rf /opt/weights/__MACOSX && \
    rm /opt/weights/TumorSynth_v1.0.zip && \
    rm /opt/weights/Task003_InnerTumor.zip  

# We accept the terms of service for the channels that we will use to install the dependencies for TumorSynth
RUN /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# We copy the file to create the nnUNetv1.7 environment
COPY create_nnUNet_v1.7_env.sh /opt
RUN chmod +x /opt/create_nnUNet_v1.7_env.sh

# We run the file to create the nnUNetv1.7 environment and install the dependencies for TumorSynth
RUN cd /opt && \
    ./create_nnUNet_v1.7_env.sh \ 
        -e /opt/conda/etc/profile.d/conda.sh \
        -m /opt/weights/Task002_Tumor \
        -n nnUNet_v1.7 \
        -d /opt/nnUNet

# We set the NNUNET_ENV_DIR environment variable to point to the nnUNetv1.7 environment [this is only for the container version]
ENV NNUNET_ENV_DIR=/opt/nnUNet
ENV nnUNet_raw_data_base=${NNUNET_ENV_DIR}/nnUNet_v1.7/nnUNet_raw_data_base
ENV nnUNet_preprocessed=${NNUNET_ENV_DIR}/nnUNet_v1.7/nnUNet_preprocessed
ENV RESULTS_FOLDER=${NNUNET_ENV_DIR}/nnUNet_v1.7/nnUNet_trained_models

# We copy the file to set the extra nnUNetv1.7 environment variables
RUN cd /opt && \
    mkdir -p /opt/conda/etc/conda/activate.d && \
    chmod +x nnUNet_v1.7_path.sh && \
    mv nnUNet_v1.7_path.sh /opt/conda/etc/conda/activate.d 

# We copy the weights for the inner tumor segmentation model into the nnUNetv1.7 environment
RUN cp -r /opt/weights/Task003_InnerTumor /opt/nnUNet/nnUNet_v1.7/nnUNet_trained_models/nnUNet/3d_fullres

# We activate the nnUnet enviroment and downgrade mkl just in case [this is only for the container version]   
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate nnUNet_v1.7 && \
    conda install "mkl<2025.0.0" && \
    conda install "numpy<2" && \
    conda clean -a -y

# We remove the weights from the /opt/weights directory to save space
RUN rm -rf /opt/weights

# Clean up a little bit the things to make the image smaller
RUN apt-get autoremove -y
RUN apt-get clean all && \
    apt-get purge

# We copy the file to initialize the environment variables for TumorSynth
COPY init.sh /opt
RUN chmod +x /opt/init.sh

# We set the permissions for the /tmp directory to be writable by anyone
RUN chmod 777 -R /tmp && \
    chmod o+t -R /tmp

# We set the working directory to /data
WORKDIR /data
