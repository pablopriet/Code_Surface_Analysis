#!/bin/bash 

# - Code adapted from HCPpipeline RibbonVolumeToSurfaceMapping.sh 
# and hcp_surface.sh by Sean Fitzgibbon
# 
# - Adapted to fetal fmri by Pablo Prieto

# --------------------------------------------------------------------------------
#                         Usage Description Function 
# --------------------------------------------------------------------------------

script_name=$(basename "${0}")

show_usage() {
    echo "Arguments:"
    echo " <datadir> The path to the folder containing the subject and session subfolders."
    echo " <subid> The subject of study name"
    echo " <sesid> The session number" 
}

# ------------------------------------------------------------------------------
#        Checking for necessary tools: FSL/msm, wb_command (workbench)
# ------------------------------------------------------------------------------

wb_command_path=$(which wb_command 2>/dev/null)
if [ -z "$wb_command_path" ]; then
    echo "${script_name}:  wb_command (workbench) is not found. Please ensure it is installed."
fi

export CARET7DIR='/Applications/workbench/bin_macosx64'

msm_path=$(which fsl 2>/dev/null)
if [ -z "$msm_path" ]; then
    echo "${script_name}:  msm is not found. Please ensure it is installed."
fi

# -- Uncomment for argument usage -- 
# # Allow script to return a Usage statement, before any other output or checking
# if [ "$#" = "0" ]; then
#     show_usage
#     exit 1
# fi
# Input arguments to be used 
# subid=$1
# sesid=$2
# datadir=$3

# Setting default arguments in the meantime
subid="CC00864XX15"
sesid="2731"
datadir_fmri="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/release_v01/derivatives/dhcp_fmri_pipeline"
datadir_anat="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/release_v01/derivatives/dhcp_anat_pipeline"


# We dont have a folder of transforms to that of dhcp36 which is common to all
# We go to nearest template.
reg_sphere_dir=""

surface_template_dir="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/Templates/dhcp_fetal_brain_surface_atlas/atlas"
volume_template_dir="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/fetal_brain_mri_atlas"

# This is effectively the path to create an output folder
dhcpdir=""

# Arguments used for next functions
BrainOrdinatesResolution="1.5"
NeighborhoodSmoothing="5"
Factor="0.5"
LeftGreyRibbonValue="1"
RightGreyRibbonValue="1"

# SmoothingFWHM=2
# SurfaceSigma=0.84925690021231426 # (FWHM divided by 2.355)

SmoothingFWHM=3
SurfaceSigma=1.2738853503184713 # (FWHM divided by 2.355)

# SmoothingFWHM=4
# SurfaceSigma=1.6985138004246285 # (FWHM divided by 2.355)


VolumeSigma=${SurfaceSigma}

###############

subdir_fmri="${datadir_fmri}/sub-${subid}/ses-${sesid}"
subdir_anat="${datadir_anat}/sub-${subid}/ses-${sesid}"
workdir="${subdir_fmri}/hcp_surface"

func="${subdir_fmri}/func/sub-CC00864XX15_ses-2731_task-rest_desc-"
fslmaths "${func}preproc_bold.nii.gz" -Tmean "${func}preproc_bold_mean.nii.gz"
func_mean="${func}preproc_bold_mean.nii.gz"

struct2func_xfm="${subdir_fmri}/xfm/sub-CC00864XX15_ses-2731_from-T2w_to-bold_mode-image"

struct2template_warp="${subdir_anat}/xfm/sub-CC00864XX15_ses-2731_from-T2w_to-dhcp36wk_mode-image.nii.gz"
struct2template_inwarp="${subdir_anat}/xfm/sub-CC00864XX15_ses-2731_from-dhcp36wk_to-T2w_mode-image.nii.gz"

func2template_warp="${subdir_fmri}/xfm/sub-CC00864XX15_ses-2731_from-bold_to-dhcp36wk_mode-image.nii.gz"

func_space_dir="${workdir}/space-func"
template_space_dir="${workdir}/space-extdhcp40wk"

# Ensures the work directory and other directories exists or creates them
mkdir -p ${workdir} ${func_space_dir} ${template_space_dir}

# ================================================================================
#                                TRANSFORM DSEG
#       From Structural Space to Functional Space & Create Subcortical ROI
# --------------------------------------------------------------------------------
# Adapted from: PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh
#
# Description:
#   - Creates a mask of subcortical structures derived from a structural segmentation.
#   - Transforms this mask into the space of the functional data, ensuring alignment.
#   - Uses the same mask in a volumetric template space.
#   - Resamples it to match the volumetric template space.
#   - Imports subcortical labels utilizing Workbench commands.
# --------------------------------------------------------------------------------
#                                  
# ================================================================================

resources=${volume_template_dir}/resources
mkdir -p ${resources}

# create struct-space subcortical mask and transform to func-space
fslmaths ${subdir_anat}/anat/sub-CC00864XX15_ses-2731_desc-drawem17_dseg.nii.gz -thr 10.5 -uthr 14.5 -bin ${resources}/subcortical_mask_striatum_talamus
fslmaths ${subdir_anat}/anat/sub-CC00864XX15_ses-2731_desc-drawem17_dseg.nii.gz -thr 6.5 -uthr 7.5 -bin ${resources}/subcortical_mask_brainstem
# we are interested in striatum, thalamus and brainstem for our T2w mask
fslmaths ${resources}/subcortical_mask_brainstem -add ${resources}/subcortical_mask_striatum_talamus ${resources}/subcortical_mask

flirt -in ${resources}/subcortical_mask\
  -ref ${func_mean} \
  -applyxfm \
  -init ${struct2func_xfm}.mat \
  -interp nearestneighbour \
  -out ${func_space_dir}/subcortical_mask

# create template-space subcortical mask and resample to BrainOrdinatesResolution

parcellations=${volume_template_dir}/parcellations

fslmaths ${parcellations}/tissue-t36.00_dhcp-19.nii.gz -thr 6 -bin ${template_space_dir}/subcortical_mask

# interested in 10, 16, 17, 15, 16
# create struct-space subcortical mask and transform to func-space
fslmaths ${parcellations}/tissue-t36.00_dhcp-19.nii.gz -thr 9.5 -uthr 10.5 -bin ${template_space_dir}/subcortical_mask_brainstem
fslmaths ${parcellations}/tissue-t36.00_dhcp-19.nii.gz -thr 13.5 -uthr 17.5 -bin ${template_space_dir}/subcortical_mask_striatum_talamus
# we are interested in striatum, thalamus and brainstem for our T2w mask
fslmaths ${template_space_dir}/subcortical_mask_brainstem -add ${template_space_dir}/subcortical_mask_striatum_talamus ${template_space_dir}/subcortical_mask

flirt -in ${template_space_dir}/subcortical_mask \
  -ref ${template_space_dir}/subcortical_mask \
  -applyisoxfm $BrainOrdinatesResolution \
  -init $FSLDIR/etc/flirtsch/ident.mat \
  -interp nearestneighbour \
  -out ${template_space_dir}/subcortical_mask

# Importing subcortical labels
${CARET7DIR}/wb_command -volume-label-import \
  ${func_space_dir}/subcortical_mask.nii.gz \
  ${resources}/subcortical-structures.txt \
  ${func_space_dir}/subcortical_mask.nii.gz \
  -discard-others -drop-unused-labels

${CARET7DIR}/wb_command -volume-label-import \
  ${template_space_dir}/subcortical_mask.nii.gz \
  ${resources}/subcortical-structures.txt \
  ${template_space_dir}/subcortical_mask.nii.gz \
  -discard-others -drop-unused-labels

# ================================================================================
#                               WARP NATIVE SURFACE
#      From Structural Space to Functional Space & Standard Template Space
# --------------------------------------------------------------------------------
# Adapted from: PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh
#
# Description:
#   - Warping Surface from Structural Space to Functional Space:
#       > For both hemispheres (left and right), surfaces in the structural space
#         are seamlessly transformed into the functional space.
#       > Further transformation into a standard template space (extdhcp40wk).
#       > Resampled surfaces align to a symmetric 32k mesh.
# --------------------------------------------------------------------------------
#                                      
# ================================================================================


for hemi in left right; do
  if [ $hemi = "left" ]; then
    structure="CORTEX_LEFT"
    hemi_upper="L"
  elif [ $hemi = "right" ]; then
    structure="CORTEX_RIGHT"
    hemi_upper="R"
  fi

  # transform native anatomical surfaces: T2w space --> func space

  for surface in wm pial midthickness inflated vinflated; do
# We need to make sure that the ${surface}_hemi-${hemi}_mesh-native_space-func.surf.gii sits onto the functional volume perfectly.
    ${CARET7DIR}/wb_command -surface-apply-affine \
      ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_hemi-${hemi}_${surface}.surf.gii\
      ${struct2func_xfm}.mat \
      ${func_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-func.surf.gii \
      -flirt \
      ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_T2w.nii.gz \
      $func_mean

    ${CARET7DIR}/wb_command -add-to-spec-file \
      ${func_space_dir}/mesh-native_space-func.wb.spec \
      $structure \
      ${func_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-func.surf.gii

    # # transform native anatomical surfaces: T2w space --> extdhcp40wk space

    # ${CARET7DIR}/wb_command -surface-apply-warpfield \
    #   ${subdir}/surface/${surface}_hemi-${hemi}_mesh-native_space-T2w.surf.gii \
    #   ${struct2template_invwarp} \
    #   ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii \
    #   -fnirt \
    #   ${struct2template_warp}
  
    # ${CARET7DIR}/wb_command -add-to-spec-file \
    #   ${template_space_dir}/mesh-native_space-extdhcp40wk.wb.spec \
    #   $structure \
    #   ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii

    # resample extdhcp40wk-space anatomical surfaces: native mesh --> dhcp32kSym mesh

    # ${CARET7DIR}/wb_command -surface-resample \
    #   ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii \
    #   ${reg_sphere_dir}/sub-${subid}_ses-${sesid}_hemi-${hemi}_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii \
    #   ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii \
    #   BARYCENTRIC \
    #   ${template_space_dir}/${surface}_hemi-${hemi}_mesh-dhcp32kSym_space-extdhcp40wk.surf.gii
    # # EVERYTHING IS ADDED ONTO A SPEC FILE IN ORDER TO HANDLE DIFFERENT TYPES OF DATA
    # ${CARET7DIR}/wb_command -add-to-spec-file \
    #   ${template_space_dir}/mesh-dhcp32kSym_space-extdhcp40wk.wb.spec \
    #   $structure \
    #   ${template_space_dir}/${surface}_hemi-${hemi}_mesh-dhcp32kSym_space-extdhcp40wk.surf.gii

  done
done

# ================================================================================
#                          RIBBON CONSTRAINED MAPPING
#                Ribbon Volume to Surface Mapping Adaptation
# --------------------------------------------------------------------------------
# Adapted from: fMRISurface/scripts/RibbonVolumeToSurfacemapping.sh
#
# Description:
#   - This procedure performs the ribbon volume to surface mapping. It constrains
#     the mapping process within the boundaries of the cortical ribbon, ensuring 
#     accuracy and consistency across different subjects.
# --------------------------------------------------------------------------------
#                                      
# ================================================================================


for hemi in left right; do

  if [ $hemi = "left" ]; then
    GreyRibbonValue="$LeftGreyRibbonValue"
  elif [ $hemi = "right" ]; then
    GreyRibbonValue="$RightGreyRibbonValue"
  fi
    # signed distance from a point in the brain to a surface is the shortest distance from that point to the surface, 
    # with a sign indicating whether the point is inside or outside of the surface.
  ${CARET7DIR}/wb_command -create-signed-distance-volume \
    ${func_space_dir}/wm_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_mean} \
    ${workdir}/${hemi}.wm.native.nii.gz

  ${CARET7DIR}/wb_command -create-signed-distance-volume \
    ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_mean} \
    ${workdir}/${hemi}.pial.native.nii.gz
    # By computing the signed distance to both surfaces and then creating binary masks, 
    # one can accurately delineate the grey matter ribbon, ensuring that subsequent analyses 
    # are constrained within this anatomically meaningful region.
  fslmaths ${workdir}/${hemi}.wm.native.nii.gz -thr 0 -bin -mul 255 ${workdir}/${hemi}.wm_thr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.wm_thr0.native.nii.gz -bin ${workdir}/${hemi}.wm_thr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 ${workdir}/${hemi}.pial_uthr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial_uthr0.native.nii.gz -bin ${workdir}/${hemi}.pial_uthr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial_uthr0.native.nii.gz -mas ${workdir}/${hemi}.wm_thr0.native.nii.gz -mul 255 ${workdir}/${hemi}.ribbon.nii.gz
  fslmaths ${workdir}/${hemi}.ribbon.nii.gz -bin -mul $GreyRibbonValue ${workdir}/${hemi}.ribbon.nii.gz
  rm ${workdir}/${hemi}.wm.native.nii.gz ${workdir}/${hemi}.wm_thr0.native.nii.gz ${workdir}/${hemi}.pial.native.nii.gz ${workdir}/${hemi}.pial_uthr0.native.nii.gz
done

fslmaths ${workdir}/left.ribbon.nii.gz -add ${workdir}/right.ribbon.nii.gz ${workdir}/ribbon_only.nii.gz
rm ${workdir}/left.ribbon.nii.gz ${workdir}/right.ribbon.nii.gz

# --------------------------------------------------------------------------------
#        MEAN, STD DEV, & COV WITHIN THE RIBBON
# --------------------------------------------------------------------------------

fslmaths ${func}preproc_bold.nii.gz -Tmean ${workdir}/mean -odt float
fslmaths ${func}preproc_bold.nii.gz -Tstd ${workdir}/std -odt float
fslmaths ${workdir}/std -div ${workdir}/mean ${workdir}/cov

fslmaths ${workdir}/cov -mas ${workdir}/ribbon_only.nii.gz ${workdir}/cov_ribbon

fslmaths ${workdir}/cov_ribbon -div $(fslstats ${workdir}/cov_ribbon -M) ${workdir}/cov_ribbon_norm
fslmaths ${workdir}/cov_ribbon_norm -bin -s $NeighborhoodSmoothing ${workdir}/SmoothNorm
fslmaths ${workdir}/cov_ribbon_norm -s $NeighborhoodSmoothing -div ${workdir}/SmoothNorm -dilD ${workdir}/cov_ribbon_norm_s$NeighborhoodSmoothing
fslmaths ${workdir}/cov -div $(fslstats ${workdir}/cov_ribbon -M) -div ${workdir}/cov_ribbon_norm_s$NeighborhoodSmoothing ${workdir}/cov_norm_modulate
fslmaths ${workdir}/cov_norm_modulate -mas ${workdir}/ribbon_only.nii.gz ${workdir}/cov_norm_modulate_ribbon

STD=$(fslstats ${workdir}/cov_norm_modulate_ribbon -S)
echo $STD
MEAN=$(fslstats ${workdir}/cov_norm_modulate_ribbon -M)
echo $MEAN
Lower=$(echo "$MEAN - ($STD * "$Factor")" | bc -l)
echo $Lower
Upper=$(echo "$MEAN + ($STD * "$Factor")" | bc -l) # changed this part. originally 0.75=$Factor
echo $Upper

good_mask="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/release_v01/derivatives/dhcp_fmri_pipeline/sub-CC00864XX15/ses-2731/func/sub-CC00864XX15_ses-2731_task-rest_desc-brain_mask.nii.gz"
##### CHANGED THIS PART

#fslmaths ${workdir}/mean -bin ${workdir}/mask
fslmaths ${workdir}/mean -bin $good_mask
fslmaths ${workdir}/cov_norm_modulate -thr $Upper -bin -sub $good_mask -mul -1 ${workdir}/goodvoxels

for hemi in left right; do

  if [ $hemi = "left" ]; then
    hemi_upper="L"
  elif [ $hemi = "right" ]; then
    hemi_upper="R"
  fi

  # mapping MEAN and COV
      #map both the mean and covariance from the volume (3D data) to the cortical surface (2D representation)
  for map in mean cov; do

    # -volume-to-surface-mapping WITH -volume-roi
        # Specifying which surface to map to (usually a midthickness or pial surface) and using constraints (
          # like ribbon constraints) to ensure accurate mapping.
    ${CARET7DIR}/wb_command -volume-to-surface-mapping \
      ${workdir}/${map}.nii.gz \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      -ribbon-constrained \
      ${func_space_dir}/wm_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii \
      -volume-roi \
      ${workdir}/goodvoxels.nii.gz
          # Dilating functuonal data onto the surface
    ${CARET7DIR}/wb_command -metric-dilate \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      10 \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      -nearest
        # Masking the functional data dilated, in order to handle the medial wall of the brain
    ${CARET7DIR}/wb_command -metric-mask \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_hemi-${hemi}_desc-medialwall_mask.shape.gii \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii

    # -volume-to-surface-mapping WITHOUT -volume-roi
        # done now globally on teh whole surface
    ${CARET7DIR}/wb_command -volume-to-surface-mapping \
      ${workdir}/${map}.nii.gz \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii \
      -ribbon-constrained \
      ${func_space_dir}/wm_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii

    ${CARET7DIR}/wb_command -metric-mask \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii \
      ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_hemi-${hemi}_desc-medialwall_mask.shape.gii \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii
  done

  # mapping GOODVOXELS
      # Previously calculated from the volume to surface mapping using ribbon constraint
  ${CARET7DIR}/wb_command -volume-to-surface-mapping \
    ${workdir}/goodvoxels.nii.gz \
    ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii \
    -ribbon-constrained \
    ${func_space_dir}/wm_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii

  ${CARET7DIR}/wb_command -metric-mask \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii \
    ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_hemi-${hemi}_desc-medialwall_mask.shape.gii \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii

  #  ribbon constrained mapping of fMRI volume to native anatomical surface (in func space)

  ${CARET7DIR}/wb_command -volume-to-surface-mapping \
    ${func}preproc_bold.nii.gz \
    ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    -ribbon-constrained \
    ${func_space_dir}/wm_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii \
    -volume-roi \
    ${workdir}/goodvoxels.nii.gz

  ${CARET7DIR}/wb_command -metric-dilate \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
    10 \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    -nearest

  ${CARET7DIR}/wb_command -metric-mask \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    ${subdir_anat}/anat/sub-${subid}_ses-${sesid}_hemi-${hemi}_desc-medialwall_mask.shape.gii \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii


  # # resample native func surface to dhcp32kSym mesh
  #     # Resampling data from functional to surface (Aligning it effectively)
  # ${CARET7DIR}/wb_command -metric-resample \
  #   ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
  #   ${reg_sphere_dir}/sub-${subid}_ses-${sesid}_hemi-${hemi}_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii \
  #   ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii \
  #   ADAP_BARY_AREA \
  #   ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
  #   -area-surfs \
  #   ${subdir}/surface/midthickness_hemi-${hemi}_mesh-native_space-T2w.surf.gii \
  #   ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_midthickness.surf.gii \
  #   -current-roi \
  #   ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii
  #     # Dilating in order to fill missed vertices
  # ${CARET7DIR}/wb_command -metric-dilate \
  #   ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
  #   ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_midthickness.surf.gii \
  #   30 \
  #   ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
  #   -nearest
  #     # Again avoiding the medial walls
  # ${CARET7DIR}/wb_command -metric-mask \
  #   ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
  #   ${resources}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii \
  #   ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii
done
