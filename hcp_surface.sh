#!/bin/bash
set -e

# This script maps dHCP volumetric fMRI data to the surface
# It is largely a vanilla implementation of the HCP Surface Pipeline
# One of the main changes is that the fMRI is mapped in the fMRI space
# The script expects the data to be in the standard (non-bids) directory structure of the dHCP fMRI pipeline
#



######## MODIFY #######

export CARET7DIR='/Applications/workbench/bin_macosx64'

subid=$1
sesid=$2
datadir=$3

reg_sphere_dir="/Users/seanf/data/dhcpSym40/transforms"
# surface_template_dir="/Users/seanf/data/dhcpSym40/template"
surface_template_dir="/Users/seanf/data/dhcpSym_template"

volume_template_dir="/Users/seanf/dhcp_resources/dhcp_volumetric_atlas_extended/atlas/templates"

dhcpdir="/Users/seanf/dev/dhcp-neonatal-fmri-pipeline/dhcp"


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

subdir="${datadir}/sub-${subid}/ses-${sesid}"
workdir="${subdir}/hcp_surface"

func="${subdir}/denoise/func_clean"
func_mean="${subdir}/denoise/func_clean_mean"

struct2func_xfm="${subdir}/reg/func-mcdc_to_struct/func-mcdc_to_struct_invaffine"

struct2template_warp="${subdir}/reg/struct_to_standard/struct_to_standard_warp.nii.gz"
struct2template_invwarp="${subdir}/reg/struct_to_standard/struct_to_standard_invwarp.nii.gz"

func2template_warp="${subdir}/reg/func-mcdc_to_standard/func-mcdc_to_standard_warp.nii.gz"

func_space_dir="${workdir}/space-func"
template_space_dir="${workdir}/space-extdhcp40wk"

resources="${dhcpdir}/resources"

mkdir -p ${workdir} ${func_space_dir} ${template_space_dir}

# ################
# transform dseg from struct space to func space, and create subcortical ROI
# adapted from PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh
# ################

# create struct-space subcortical mask and transform to func-space

fslmaths ${subdir}/import/T2w_dseg -thr 6 -bin ${subdir}/import/T2w_scmask
flirt -in ${subdir}/import/T2w_scmask \
  -ref ${func_mean} \
  -applyxfm \
  -init ${struct2func_xfm}.mat \
  -interp nearestneighbour \
  -out ${func_space_dir}/subcortical_mask

# create template-space subcortical mask and resample to BrainOrdinatesResolution

fslmaths ${volume_template_dir}/week40_tissue_dseg.nii.gz -thr 6 -bin ${template_space_dir}/subcortical_mask
flirt -in ${template_space_dir}/subcortical_mask \
  -ref ${template_space_dir}/subcortical_mask \
  -applyisoxfm $BrainOrdinatesResolution \
  -init $FSLDIR/etc/flirtsch/ident.mat \
  -interp nearestneighbour \
  -out ${template_space_dir}/subcortical_mask

# import subcortical labels

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

# ################
# warp native surface from struct space to func space
# adapted from PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh
# ################

for hemi in left right; do
  if [ $hemi = "left" ]; then
    structure="CORTEX_LEFT"
    hemi_upper="L"
  elif [ $hemi = "right" ]; then
    structure="CORTEX_RIGHT"
    hemi_upper="R"
  fi

  # transform native anatomical surfaces: T2w space --> func space

  for surface in white pial midthickness inflated veryinflated; do

    ${CARET7DIR}/wb_command -surface-apply-affine \
      ${subdir}/surface/${surface}_hemi-${hemi}_mesh-native_space-T2w.surf.gii \
      ${struct2func_xfm}.mat \
      ${func_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-func.surf.gii \
      -flirt \
      ${subdir}/import/T2w.nii.gz \
      ${subdir}/denoise/func_clean_mean.nii.gz

    ${CARET7DIR}/wb_command -add-to-spec-file \
      ${func_space_dir}/mesh-native_space-func.wb.spec \
      $structure \
      ${func_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-func.surf.gii

    # transform native anatomical surfaces: T2w space --> extdhcp40wk space

    ${CARET7DIR}/wb_command -surface-apply-warpfield \
      ${subdir}/surface/${surface}_hemi-${hemi}_mesh-native_space-T2w.surf.gii \
      ${struct2template_invwarp} \
      ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii \
      -fnirt \
      ${struct2template_warp}

    ${CARET7DIR}/wb_command -add-to-spec-file \
      ${template_space_dir}/mesh-native_space-extdhcp40wk.wb.spec \
      $structure \
      ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii

    # resample extdhcp40wk-space anatomical surfaces: native mesh --> dhcp32kSym mesh

    ${CARET7DIR}/wb_command -surface-resample \
      ${template_space_dir}/${surface}_hemi-${hemi}_mesh-native_space-extdhcp40wk.surf.gii \
      ${reg_sphere_dir}/sub-${subid}_ses-${sesid}_hemi-${hemi}_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii \
      ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii \
      BARYCENTRIC \
      ${template_space_dir}/${surface}_hemi-${hemi}_mesh-dhcp32kSym_space-extdhcp40wk.surf.gii

    ${CARET7DIR}/wb_command -add-to-spec-file \
      ${template_space_dir}/mesh-dhcp32kSym_space-extdhcp40wk.wb.spec \
      $structure \
      ${template_space_dir}/${surface}_hemi-${hemi}_mesh-dhcp32kSym_space-extdhcp40wk.surf.gii

  done

done

# ################
# ribbon constrained mapping
# adapted from fMRISurface/scripts/RibbonVolumeToSurfacemapping.sh
# ################

for hemi in left right; do

  if [ $hemi = "left" ]; then
    GreyRibbonValue="$LeftGreyRibbonValue"
  elif [ $hemi = "right" ]; then
    GreyRibbonValue="$RightGreyRibbonValue"
  fi

  ${CARET7DIR}/wb_command -create-signed-distance-volume \
    ${func_space_dir}/white_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_mean}.nii.gz \
    ${workdir}/${hemi}.white.native.nii.gz

  ${CARET7DIR}/wb_command -create-signed-distance-volume \
    ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_mean}.nii.gz \
    ${workdir}/${hemi}.pial.native.nii.gz

  fslmaths ${workdir}/${hemi}.white.native.nii.gz -thr 0 -bin -mul 255 ${workdir}/${hemi}.white_thr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.white_thr0.native.nii.gz -bin ${workdir}/${hemi}.white_thr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 ${workdir}/${hemi}.pial_uthr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial_uthr0.native.nii.gz -bin ${workdir}/${hemi}.pial_uthr0.native.nii.gz
  fslmaths ${workdir}/${hemi}.pial_uthr0.native.nii.gz -mas ${workdir}/${hemi}.white_thr0.native.nii.gz -mul 255 ${workdir}/${hemi}.ribbon.nii.gz
  fslmaths ${workdir}/${hemi}.ribbon.nii.gz -bin -mul $GreyRibbonValue ${workdir}/${hemi}.ribbon.nii.gz
  rm ${workdir}/${hemi}.white.native.nii.gz ${workdir}/${hemi}.white_thr0.native.nii.gz ${workdir}/${hemi}.pial.native.nii.gz ${workdir}/${hemi}.pial_uthr0.native.nii.gz
done

fslmaths ${workdir}/left.ribbon.nii.gz -add ${workdir}/right.ribbon.nii.gz ${workdir}/ribbon_only.nii.gz
rm ${workdir}/left.ribbon.nii.gz ${workdir}/right.ribbon.nii.gz

fslmaths ${func} -Tmean ${workdir}/mean -odt float
fslmaths ${func} -Tstd ${workdir}/std -odt float
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
Lower=$(echo "$MEAN - ($STD * $Factor)" | bc -l)
echo $Lower
Upper=$(echo "$MEAN + ($STD * $Factor)" | bc -l)
echo $Upper

fslmaths ${workdir}/mean -bin ${workdir}/mask
fslmaths ${workdir}/cov_norm_modulate -thr $Upper -bin -sub ${workdir}/mask -mul -1 ${workdir}/goodvoxels

for hemi in left right; do

  if [ $hemi = "left" ]; then
    hemi_upper="L"
  elif [ $hemi = "right" ]; then
    hemi_upper="R"
  fi

  # mapping MEAN and COV

  for map in mean cov; do

    # -volume-to-surface-mapping WITH -volume-roi

    ${CARET7DIR}/wb_command -volume-to-surface-mapping \
      ${workdir}/${map}.nii.gz \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      -ribbon-constrained \
      ${func_space_dir}/white_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii \
      -volume-roi \
      ${workdir}/goodvoxels.nii.gz

    ${CARET7DIR}/wb_command -metric-dilate \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      10 \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      -nearest

    ${CARET7DIR}/wb_command -metric-mask \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii \
      ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii \
      ${workdir}/${map}_hemi-${hemi}_mesh-native.func.gii

    # -volume-to-surface-mapping WITHOUT -volume-roi

    ${CARET7DIR}/wb_command -volume-to-surface-mapping \
      ${workdir}/${map}.nii.gz \
      ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii \
      -ribbon-constrained \
      ${func_space_dir}/white_hemi-${hemi}_mesh-native_space-func.surf.gii \
      ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii

    ${CARET7DIR}/wb_command -metric-mask \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii \
      ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii \
      ${workdir}/${map}_all_hemi-${hemi}_mesh-native.func.gii
  done

  # mapping GOODVOXELS

  ${CARET7DIR}/wb_command -volume-to-surface-mapping \
    ${workdir}/goodvoxels.nii.gz \
    ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii \
    -ribbon-constrained \
    ${func_space_dir}/white_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${func_space_dir}/pial_hemi-${hemi}_mesh-native_space-func.surf.gii

  ${CARET7DIR}/wb_command -metric-mask \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii \
    ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii \
    ${workdir}/goodvoxels_hemi-${hemi}_mesh-native.shape.gii

  #  ribbon constrained mapping of fMRI volume to native anatomical surface (in func space)

  ${CARET7DIR}/wb_command -volume-to-surface-mapping \
    ${func}.nii.gz \
    ${func_space_dir}/midthickness_hemi-${hemi}_mesh-native_space-func.surf.gii \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    -ribbon-constrained \
    ${func_space_dir}/white_hemi-${hemi}_mesh-native_space-func.surf.gii \
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
    ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii


  # resample native func surface to dhcp32kSym mesh

  ${CARET7DIR}/wb_command -metric-resample \
    ${workdir}/func_hemi-${hemi}_mesh-native.func.gii \
    ${reg_sphere_dir}/sub-${subid}_ses-${sesid}_hemi-${hemi}_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii \
    ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii \
    ADAP_BARY_AREA \
    ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
    -area-surfs \
    ${subdir}/surface/midthickness_hemi-${hemi}_mesh-native_space-T2w.surf.gii \
    ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_midthickness.surf.gii \
    -current-roi \
    ${subdir}/surface/medialwall_hemi-${hemi}_mesh-native.shape.gii

  ${CARET7DIR}/wb_command -metric-dilate \
    ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
    ${surface_template_dir}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_midthickness.surf.gii \
    30 \
    ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
    -nearest

  ${CARET7DIR}/wb_command -metric-mask \
    ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii \
    ${resources}/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii \
    ${workdir}/func_hemi-${hemi}_mesh-dhcp32kSym.func.gii
done

# ################
# create func-space subcortical dense time-series
# adapted from fMRISurface/scripts/SubcorticalProcessing.sh
# ################

# create func-space subcortical dense time-series

${CARET7DIR}/wb_command -cifti-create-dense-timeseries \
  ${func_space_dir}/func_space-func.dtseries.nii \
  -volume \
  $func.nii.gz \
  ${func_space_dir}/subcortical_mask.nii.gz

# dilate out any exact zeros in the input data, for instance if the brain mask is wrong. 
# Note that the CIFTI space cannot contain zeros to produce a valid CIFTI file (dilation also occurs below).
${CARET7DIR}/wb_command -cifti-dilate \
  ${func_space_dir}/func_space-func.dtseries.nii \
  COLUMN 0 30 \
  ${func_space_dir}/func_space-func.dtseries.nii

# Create atlas subcortical template cifti
${CARET7DIR}/wb_command -cifti-create-label \
  ${template_space_dir}/subcortical_mask.dlabel.nii \
  -volume ${template_space_dir}/subcortical_mask.nii.gz \
  ${template_space_dir}/subcortical_mask.nii.gz

# resample dense-time-series from func -> template space
${CARET7DIR}/wb_command -cifti-resample \
  ${func_space_dir}/func_space-func.dtseries.nii \
  COLUMN \
  ${template_space_dir}/subcortical_mask.dlabel.nii \
  COLUMN \
  ADAP_BARY_AREA \
  CUBIC \
  ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii \
  -volume-predilate 10 \
  -warpfield ${func2template_warp} -fnirt ${volume_template_dir}/week40_T2w.nii.gz

${CARET7DIR}/wb_command -cifti-dilate \
  ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii \
  COLUMN 0 30 \
  ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii

# write output volume, delete temporary
${CARET7DIR}/wb_command -cifti-separate \
  ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii \
  COLUMN \
  -volume-all \
  ${template_space_dir}/subcortical_space-extdhcp40wk.nii.gz

rm -f ${func_space_dir}/func_space-func.dtseries.nii 
rm -f ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii

# ################
# Create dense-time-series CIFTI (space==extdhcp40wk; mesh==dhcp32kSym)
# adapted from fMRISurface/scripts/CreateDenseTimeseries.sh
# ################

TR_vol=`fslinfo ${func} | grep pixdim4 | cut -f 3`

${CARET7DIR}/wb_command -cifti-create-dense-timeseries \
  ${workdir}/func_mesh-dhcp32kSym_space-extdhcp40wk.dtseries.nii \
  -left-metric ${workdir}/func_hemi-left_mesh-dhcp32kSym.func.gii \
  -roi-left ${resources}/week-40_hemi-left_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii \
  -right-metric ${workdir}/func_hemi-right_mesh-dhcp32kSym.func.gii \
  -roi-right ${resources}/week-40_hemi-right_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii \
  -volume ${template_space_dir}/subcortical_space-extdhcp40wk.nii.gz ${template_space_dir}/subcortical_mask.nii.gz \
  -timestep "$TR_vol"

rm -f ${template_space_dir}/subcortical_space-extdhcp40wk.nii.gz ${template_space_dir}/subcortical_mask.nii.gz

# spatially smooth CIFTI 

${CARET7DIR}/wb_command -cifti-smoothing \
  ${workdir}/func_mesh-dhcp32kSym_space-extdhcp40wk.dtseries.nii \
  ${SurfaceSigma} \
  ${VolumeSigma} \
  COLUMN \
  ${workdir}/func_mesh-dhcp32kSym_space-extdhcp40wk_desc-smooth${SmoothingFWHM}mm.dtseries.nii \
  -left-surface \
  ${surface_template_dir}/week-40_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii \
  -right-surface \
  ${surface_template_dir}/week-40_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii \
  -fix-zeros-volume \
  -fix-zeros-surface