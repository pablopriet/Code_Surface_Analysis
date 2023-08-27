#!/bin/bash
out_folder="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/Templates/Output_MSM"
out_feature_folder="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/Templates/Output_MSM/FeatureCombination"
atlas_folder="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/Templates/dhcp_fetal_brain_surface_atlas/atlas"

echo "Merging Features from curvature and sulcus features from week 34" 
# change it to solely sulcus
wb_command -metric-merge $out_feature_folder/fetal.week34.left.curvature.sulc.shape.gii -metric $atlas_folder/fetal.week34.left.curvature.shape.gii -metric $atlas_folder/fetal.week34.left.sulc.shape.gii
echo "Merging Features from curvature and sulcus features from week 35"   
wb_command -metric-merge $out_feature_folder/fetal.week35.left.curvature.sulc.shape.gii -metric $atlas_folder/fetal.week35.left.curvature.shape.gii -metric $atlas_folder/fetal.week35.left.sulc.shape.gii
echo "Merging Features from curvature and sulcus features from week 36"   
wb_command -metric-merge $out_feature_folder/fetal.week36.left.curvature.sulc.shape.gii -metric $atlas_folder/fetal.week36.left.curvature.shape.gii -metric $atlas_folder/fetal.week36.left.sulc.shape.gii
echo "Multimodal Surface Matching between Week 34 and Week 35"   
/Applications/FSL/bin/msm --inmesh=$atlas_folder/fetal.week34.left.sphere.surf.gii --refmesh=$atlas_folder/fetal.week35.left.sphere.surf.gii --indata=$out_feature_folder/fetal.week34.left.curvature.sulc.shape.gii --refdata=$out_feature_folder/fetal.week35.left.curvature.sulc.shape.gii --out=$out_folder/L34_L35_Curvature_Sulc_Wrap.
echo "Multimodal Surface Matching between Week 35 and Week 36" 
/Applications/FSL/bin/msm --inmesh=$atlas_folder/fetal.week35.left.sphere.surf.gii --refmesh=$atlas_folder/fetal.week36.left.sphere.surf.gii --indata=$out_feature_folder/fetal.week35.left.curvature.sulc.shape.gii --refdata=$out_feature_folder/fetal.week36.left.curvature.sulc.shape.gii --out=$out_folder/L35_L36_Curvature_Sulc_Wrap.
echo "Concatenating Registrations from week 34 to week 36" 
wb_command -surface-sphere-project-unproject $out_folder/L34_L35_Curvature_Sulc_Wrap.sphere.reg.surf.gii $atlas_folder/fetal.week35.left.sphere.surf.gii $out_folder/L35_L36_Curvature_Sulc_Wrap.sphere.reg.surf.gii $out_folder/L34_L36_Curvature_Sulc_Warp.sphere.surf.gii
echo "Resampling registrations to output sphere" 
#/Applications/FSL/bin/msmresample $out_folder/L34_L36_Curvature_Sulc_Warp.sphere.surf.gii $out_folder/L34_L36_Curvature_Sulc_Warp.transformed_and_reprojected -labels $out_feature_folder/fetal.week34.left.curvature.sulc.shape.gii -project $atlas_folder/fetal.week36.left.sphere.surf.gii -adap_bary 
wb_command -metric-resample $out_feature_folder/fetal.week34.left.curvature.sulc.shape.gii $out_folder/L34_L36_Curvature_Sulc_Warp.sphere.surf.gii $atlas_folder/fetal.week36.left.sphere.surf.gii ADAP_BARY_AREA -area-surfs $atlas_folder/fetal.week34.left.midthickness.surf.gii $atlas_folder/fetal.week36.left.midthickness.surf.gii $out_folder/L34_L36_Curvature_Sulc_Warp.transformed_and_reprojected.shape.gii
