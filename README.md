# TumorSynth
mri_TumorSynth - To segment the healthy brain tissue and tumor in MR scans with tumor with support for multi-sequence MR inputs (T1, T1CE, T2, FLAIR or any other). [See TumorSynth website](https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth)

# Installation

Read from here: [FreeSurfer Wiki - TumorSynth](https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth#Installation)

# Key links
- Conda installation [v3.9_25.9.1-3]: [Conda website](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)
- Model and weights for whole tumor segementation: [TumourSynth_v1.0.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/EWsIGJOFbD9MiPyQnGhjGHwBquaWhxJfEAzbfs6v5BvFzA?e=JQHlSQ) 
- Model and weights for inner tumor segementation: [Task003_InnerTumor.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/IQCJJdWxSqPsQpKaxW3yFWikARbdkwcgnY8nkd-5HUezl3Q?e=E7i74D) 
- Installation script: [create_nnUNet_v1.7_env.sh](https://github.com/fprados/TumorSynth/blob/main/docker/create_nnUNet_v1.7_env.sh)

# Docker Installation

To build the docker you need to do:

```
./docker/docker_build.sh
````

To run the docker for testing mri_tumorsynth:

```
./docker/docker_run.sh
````

The Docker container is configured to build and use the current directory as the working directory (this can be modified if needed). Once the container is running, you must activate the conda-nnUnetv1.7 environment from within the container before executing mri_tumorsynth.

```
source /opt/init.sh
mri_tumorsynth --i BraTS19_CBICA_APZ_1/t1ce.nii.gz --o tumor_mask_APZ_1.nii.gz --wholetumor
```