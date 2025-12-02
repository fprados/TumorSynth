#!/usr/bin/env bash

# Exit at any error
set -e

# Make sure FreeSurfer is sourced
[ ! -e "$FREESURFER_HOME" ] && echo "error: freesurfer has not been properly sourced" && exit 1

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
  echo "   * Mode 3. To process multiple scans, use a text file with input paths (one per line) and specify a corresponding output text file."
  echo " "
  echo "The command line options are: "
  echo " "
  echo "--i [IMAGE_OR_CSV_FILE] "
  echo "           Input image to segment - mode 1 and 2, or "
  echo "           A CSV file with list of scans - mode 3 (required argument) each line is a path to a skull-stripped, SRI-24-registered scan"
  echo "--o [MASK_OR_CSV_FILE] "
  echo "           Path to save segmentation mask (same format as input) - mode 1 and 2, or "
  echo "           Output CSV file where each line is the path to save the corresponding segmentation mask - mode 3."
  echo "--i2 [IMAGE] "
  echo "           Extra input image to segment - mode 2 (optional)"
  echo "--i3 [IMAGE] "
  echo "           Extra input image to segment - mode 2 (optional)"
  echo "--vol [MASK_OR_CSV_FILE]"
  echo "           Volume output file (same format as input) - mode 1 and 2, or "
  echo "           Path to CSV file for saving volumes of all segmented structures - mode 3."
  echo "--wholetumor "
  echo "           Whole-tumor + healthy tissue mode. Outputs combined mask of healthy brain tissue and whole tumor (includes edema, enhancing tumor, non-enhancing tumor). Input must be skull-stripped and registered to SRI-24 template. "
  echo "--innertumor "
  echo "           Inner tumor substructure mode. Outputs BraTS-compliant subclasses: Tumor Core (TC), Non-Enhancing Tumor (NET), and Edema. Input must be a tumor ROI image (prepare by multiplying raw scan with --wholetumor output mask)."
  echo "--threads [THREADS] "    
  echo "           Number of cores to be used. You can use -1 to use all available cores. Default is -1 (optional)"
  echo "--cpu [DEV] "     
  echo "           Bypasses GPU detection and runs on CPU (optional) "

  exit 0
fi

# Try to find TumorSynth model files
MODEL_FILE="$NNUNET_ENV_DIR/nnUNet_v1.7/nnUNet_trained_models/mri_TumorSynth_v1.0/nnUNetTrainerV2__nnUNetPlansv2.1/plans.pkl"

# if model file not found, print instructions for download and exit
if [ ! -f "$MODEL_FILE" ] ;
then
    echo "Unable to located some dependencies, please follow the steps below to install them, then rerun the script."
    echo ""
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

# Create command and run!
BASEPATH="$FREESURFER_HOME/python/packages/mri_TumorSynth/" 
cmd="nnUNet_predict $@ -tr nnUNetTrainerV2 -ctr nnUNetTrainerV2CascadeFullRes -m 3d_fullres -p nnUNetPlansv2.1 -t 002 -f 0 1 2 3 4"
echo "Running command:"
echo $cmd
echo "  "
$cmd