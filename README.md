# TumorSynth
mri_TumorSynth - To segment the healthy brain tissue and tumor in MR scans with tumor with support for multi-sequence MR inputs (T1, T1CE, T2, FLAIR or any other). [See TumorSynth website](https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth)

# Installation

Read from here: [FreeSurfer Wiki - TumorSynth](https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth#Installation)

# Key links
- Conda installation [v3.9_25.9.1-3]: [Conda website](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)
- Model and weights for whole tumor segementation: [TumourSynth_v1.0.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/EWsIGJOFbD9MiPyQnGhjGHwBquaWhxJfEAzbfs6v5BvFzA?e=JQHlSQ) 
- Model and weights for inner tumor segementation: [Task003_InnerTumor.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/IQCJJdWxSqPsQpKaxW3yFWikARbdkwcgnY8nkd-5HUezl3Q?e=E7i74D) 
- Installation script: [create_nnUNet_v1.7_env.sh](https://github.com/fprados/TumorSynth/blob/main/docker/create_nnUNet_v1.7_env.sh)

# Building the Docker Image

## 1. Clone the Repository

First, clone the TumorSynth repository to your local machine:

```
git clone https://github.com/fprados/TumorSynth.git 
```

## 2. Download the Model Weights

From within the cloned repository, create the `extra-data` subdirectory inside the docker folder and download the required weights:

```
mkdir -p docker/extra-data
cd docker/extra-data
```

You need to download to the `extra-data` subdirectory the two following files:

- Model and weights for whole tumor segementation: [TumourSynth_v1.0.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/EWsIGJOFbD9MiPyQnGhjGHwBquaWhxJfEAzbfs6v5BvFzA?e=JQHlSQ) 
- Model and weights for inner tumor segementation: [Task003_InnerTumor.zip](https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/IQCJJdWxSqPsQpKaxW3yFWikARbdkwcgnY8nkd-5HUezl3Q?e=E7i74D) 

The filenames need to be as follow: `TumorSynth_v1.0.zip` and `Task003_InnerTumor.zip`

## 3. Build the Docker Image

Navigate to the docker directory inside the TumorSynth repository and run:

```
./docker_build.sh
```

The Docker image is currently built using the latest FreeSurfer nightly build. Since FreeSurfer is under continuous development and new versions are released frequently, you may prefer to use a specific version. In that case:

- Download the desired FreeSurfer version locally (e.g., into the `extra-data` subdirectory).

- Modify the corresponding lines (66–67) in the `Dockerfile` to copy your selected version into the container.

# Running the Docker Container

Once built, to run the docker for testing `mri_tumorsynth`, you need to type from the docker subdirectory:

```
./docker_run.sh
```

The Docker container is configured to use the current directory as the working directory by default (this can be adjusted if needed).

After the container starts, you must activate the `conda-nnUnetv1.7` environment before running `mri_tumorsynth`:

```
source /opt/init.sh
mri_tumorsynth --i BraTS19_CBICA_APZ_1/t1ce.nii.gz --o tumor_mask_APZ_1.nii.gz --wholetumor
```