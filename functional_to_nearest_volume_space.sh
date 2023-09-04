#!/bin/bash

# Functional to Volumetric Template Space # Doing it for case sub-CC00864XX15
input_folder="/Volumes/DiscoPrieto/release_v01/derivatives/dhcp_fmri_pipeline"
warping="$input_folder/sub-CC00864XX15/ses-2731/xfm/sub-CC00864XX15_ses-2731_from-bold_to-dhcp36wk_mode-image.nii.gz"
template="/Volumes/DiscoPrieto/fetal_brain_mri_atlas/structural/t2-t36.00.nii"
struc_map="$input_folder/sub-CC00864XX15/ses-2731/func/sub-CC00864XX15_ses-2731_task-rest_desc-preproc_bold.nii.gz"
output_folder="/Volumes/DiscoPrieto/release_v01/warped_struct_func"

applywarp -i $struc_map -r $template -w $warping -o $output_folder --interp=trilinear --rel


# Individual surfaces to Volumetric Template Space # Doing it for case sub-CC00864XX15
input_folder="/Volumes/DiscoPrieto/release_v01/derivatives/dhcp_anat_pipeline"
warping="$input_folder/sub-CC00864XX15/ses-2731/xfm/sub-CC00864XX15_ses-2731_from-T2w_to-dhcp36wk_mode-image.nii.gz"
template="/Volumes/DiscoPrieto/fetal_brain_mri_atlas/structural/t2-t36.00.nii"
struc_map="$input_folder/sub-CC00864XX15/ses-2731/anat/sub-CC00864XX15_ses-2731_thickness.dscalar.nii"
output_folder="/Volumes/DiscoPrieto/release_v01/warped_struct_surf"

applywarp -i $struc_map -r $template -w $warping -o $output_folder --interp=trilinear --rel

