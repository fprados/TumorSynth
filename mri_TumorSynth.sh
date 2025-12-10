#!/usr/bin/env bash

# Exit at any error
set -e

# If requesting help
if  [ $# == 1 ] && [  $1 == "--help" ]
then
  echo " "
  echo "U-Net trained to segment the healthy brain tissue and tumor in MR scans with tumor with support for multi-sequence MR inputs (T1, T1CE, T2, FLAIR)."
  echo " "
  echo "The code relies on: "
  echo "   TumorSynth: Integrated Brain Tumor and Tissue Segmentation in Brain MRI Scans of any Resolution and Contrast "
  echo "      Jiaming Wu et al. (under revision)"
  echo " "
  echo " "
  echo "Usage: "
  echo " "
  echo "mri_TumorSynth supports three primary usage scenarios, with flexibility for single or multi-sequence inputs: "
  echo ""
  echo "   * Mode 1. Whole-tumor + healthy tissue segmentation (primary use case) or inner tumor substructure segmentation (requires tumor ROI input). "
  echo "   * Mode 2. Combine T1CE, T2, and FLAIR for better segmentation of heterogeneous tumors. "
  echo " "
  echo "The command line options are: "
  echo " "
  echo "--i [IMAGE] "
  echo "           Input image to segment, it is skull-stripped, SRI-24-registered scan - mode 1 and 2"
  echo "--o [MASK] "
  echo "           Path to save segmentation mask (same format as input) - mode 1 and 2"
  echo "--i2 [IMAGE] "
  echo "           Extra input image to segment - mode 2 (optional)"
  echo "--i3 [IMAGE] "
  echo "           Extra input image to segment - mode 2 (optional)"
  echo "--vol [CSV_FILE]"
  echo "           Path to CSV file for saving volumes of all segmented structures - mode 1 and 2"
  echo "--wholetumor "
  echo "           [Default] Whole-tumor + healthy tissue mode. Outputs combined mask of healthy brain tissue and whole tumor (includes edema, enhancing tumor, non-enhancing tumor). Input must be skull-stripped and registered to SRI-24 template. "
  echo "--innertumor "
  echo "           Inner tumor substructure mode. Outputs BraTS-compliant subclasses: Tumor Core (TC), Non-Enhancing Tumor (NET), and Edema. Input must be a tumor ROI image (prepare by multiplying raw scan with --wholetumor output mask)."
  echo "--threads [THREADS] "    
  echo "           Number of cores to be used. You can use -1 to use all available cores. Default is -1 (optional)"
  echo "--cpu "     
  echo "           Bypasses GPU detection and runs on CPU (optional) "

  exit 0
fi

# For each execution we work in a different temporaly directory where we have right access and writting permissions 
working_dir=`mktemp -d -t TumorSynth_`
dir_list=''
DEVICE='GPU'
NUM_THREADS=8
INNER_TUMOR=0

# For sanity check we output on the screen all the variables
echo " "
echo "mri_TumorSynth - U-Net trained to segment the healthy brain tissue and tumor in MR scans with tumor with support for multi-sequence MR inputs (T1, T1CE, T2, FLAIR)."
echo " "
echo "Temporal working directory: ${working_dir}"
echo " "
echo "***** INPUT PARAMETERS *****"
while [[ $# -gt 0 ]]; do
  case $1 in
    --i)
      mkdir -p ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs1
      extension="${2#*.}"
      cp ${2} ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs1/input_0000.${extension}
      dir_list="${dir_list}${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs1,"
      echo "INPUT FILE 1: $2 copied at ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs1/input_0000.${extension}"
      shift # past argument
      shift # past value
      ;;
    --i2)
      mkdir -p ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs2
      extension="${2#*.}"
      cp ${2} ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs2/input_0000.${extension}
      dir_list="${dir_list}${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs2,"
      echo "INPUT FILE 2: $2 copied at ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs2/input_0000.${extension}"
      shift # past argument
      shift # past value
      ;;
    --i3)
      mkdir -p ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs3
      extension="${2#*.}"
      cp ${2} ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs3/input_0000.${extension}
      dir_list="${dir_list}${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs3,"
      echo "INPUT FILE 3: $2 copied at ${working_dir}/nnUNet_raw_data_base/nnUNet_raw_data/Task002_Tumor/ImagesTs3/input_0000.${extension}"
      shift # past argument
      shift # past value
      ;;
    --o)
      OUTPUT_FILE="$2"
      echo "OUTPUT FILE: $2"
      shift # past argument
      shift # past value
      ;;
    --vol)
      VOL_FILE="$2"
      echo "OUTPUT FILE: $2"
      shift # past argument
      shift # past value
      ;;
    --wholetumor)
      MODEL_NAME="nnUNetPlansv2.1"
      shift # past argument
      ;;
    --innertumor)
      MODEL_NAME="NA"
      INNER_TUMOR=1
      shift # past argument
      ;;
    --threads)
      NUM_THREADS="$2"
      shift # past argument
      shift # past value
      ;;
    --cpu)
      DEVICE="cpu"
      shift # past argument
      ;;
  esac
done
echo "MODEL NAME: ${MODEL_NAME}"
echo "NUMBER OF THREADS: ${NUM_THREADS}"
echo "DEVICE: ${DEVICE}"
echo "****************************"

# Setting up the number of threads
export OMP_THREAD_LIMIT=${NUM_THREADS}
export OMP_NUM_THREADS=${OMP_THREAD_LIMIT}

echo " "
echo "Checking that we can find the model..."
# Try to find TumorSynth model files
MODEL_FILE="$NNUNET_ENV_DIR/nnUNet_v1.7/nnUNet_trained_models/nnUNet/3d_fullres/Task002_Tumor/nnUNetTrainerV2__${MODEL_NAME}/plans.pkl"

# If model file not found, print instructions for download and exit
if [ ! -f "$MODEL_FILE" ] ;
then
    echo "Unable to located some dependencies, please follow the steps below to install them, then rerun the script."
    echo " "
    echo "File missing: $MODEL_FILE"
    echo " "
    if [ ! -f "$MODEL_FILE" ]; then 
        echo " "
        echo "   Machine learning model file not found. Please download from from: "
        echo "     https://liveuclac-my.sharepoint.com/:u:/g/personal/rmapfpr_ucl_ac_uk/EWsIGJOFbD9MiPyQnGhjGHwBquaWhxJfEAzbfs6v5BvFzA?e=JQHlSQ "
        echo "   and follow installation instructions from:  "
        echo "     https://surfer.nmr.mgh.harvard.edu/fswiki/TumorSynth#Installation"
        echo " "
    fi
    exit 1    
fi
echo "Model found: ${MODEL_NAME} at ${MODEL_FILE}"

# We prepare an empty file for the output
if [ "${INNER_TUMOR}" = "0" ] ;
then
  # The case of the whole tumor segmentation (just 1 value per mask)
  fslmaths ${dir_list/,*/}/input_0000.* -mul 0 ${OUTPUT_FILE}
else
  # The inner tumor has 3 labels and background
  fslmaths ${dir_list/,*/}/input_0000.* -mul 0 ${working_dir}/label0.nii.gz
  fslmaths ${dir_list/,*/}/input_0000.* -mul 0 ${working_dir}/label1.nii.gz
  fslmaths ${dir_list/,*/}/input_0000.* -mul 0 ${working_dir}/label2.nii.gz
  fslmaths ${dir_list/,*/}/input_0000.* -mul 0 ${working_dir}/label3.nii.gz
fi

# Setting up local environment variables
nnUNet_preprocessed=${working_dir}/nnUNet_preprocessed
RESULTS_FOLDER=${MODEL_FILE/nnUNet\/*/}
nnUNet_raw_data_base=${working_dir}/nnUNet_raw_data_base

echo "Ready to run the inference..."
# Create command and run for each input dataset!
i=0
for data_dir in $(echo "$dir_list" | tr ',' '\n'); do 
  mkdir -p ${working_dir}/output${i}
  cmd="nnUNet_predict -i ${data_dir} -o ${working_dir}/output${i} -tr nnUNetTrainerV2 -ctr nnUNetTrainerV2CascadeFullRes -m 3d_fullres -p ${MODEL_NAME} -t 002 -f 0 1 2 3 4 "
  echo "Running command:"
  echo $cmd
  echo "  "
  $cmd

  # We sum all the outputs
  if [ "${INNER_TUMOR}" = "0" ] ;
  then
    # The case of the whole tumor segmentation (just 1 value per mask)
    fslmaths ${OUTPUT_FILE} -add `ls ${working_dir}/output${i}/*.* | grep nii` ${OUTPUT_FILE}
  else
    # The inner tumor has 3 labels
    fslmaths `ls ${working_dir}/output${i}/*.* | grep nii` -thr 0.5 -uthr 1.5 -bin -add ${working_dir}/label1.nii.gz ${i} ${working_dir}/label1.nii.gz
    fslmaths `ls ${working_dir}/output${i}/*.* | grep nii` -thr 1.5 -uthr 2.5 -bin -add ${working_dir}/label2.nii.gz ${i} ${working_dir}/label2.nii.gz
    fslmaths `ls ${working_dir}/output${i}/*.* | grep nii` -thr 2.5 -uthr 3.5 -bin -add ${working_dir}/label3.nii.gz ${i} ${working_dir}/label3.nii.gz
  fi
  ((i++))
done

echo "Fusing the results for computing the final mask"
# We divide the final lesion mask by the number of outputs, it is a simple Majority Voting.
if [ "${INNER_TUMOR}" = "0" ] ;
then
  # The case of the whole tumor segmentation (just 1 value per mask)
  fslmaths ${OUTPUT_FILE} -div ${i} ${OUTPUT_FILE}
else
  # The inner tumor has 3 labels
  fslmaths ${working_dir}/label1.nii.gz -div ${i} ${working_dir}/label1.nii.gz
  fslmaths ${working_dir}/label2.nii.gz -div ${i} ${working_dir}/label2.nii.gz
  fslmaths ${working_dir}/label3.nii.gz -div ${i} ${working_dir}/label3.nii.gz
  merge -t ${working_dir}/all.nii.gz ${working_dir}/label0.nii.gz ${working_dir}/label1.nii.gz ${working_dir}/label2.nii.gz ${working_dir}/label3.nii.gz
  fslmaths ${working_dir}/all.nii.gz -Tmaxn ${OUTPUT_FILE}
fi
#cp ${working_dir}/output*/*.* ${PWD}/

echo "Removing temporal directories"
rm -rf ${working_dir}
echo "The tumor mask is in: ${OUTPUT_FILE}"
echo "Have a nice day!!!"