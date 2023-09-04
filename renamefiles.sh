#! /bin/bash
out_folder="/Users/pabloprieto/Library/CloudStorage/OneDrive-Personal/Documentos/3rd_Year_Biomedical_Engineering_MENG/Summer_Studentship/Templates/Output_MSM"
concat_folder="$out_folder/concatenated_registrations_36_GL_Curv_Sulc"
reprojected_metrics="$out_folder/reprojected_metrics"


# Loop from 21 to 36
for week in {21..35}; do
    next_week=$((week+1))
    for side in left right; do
        # # Rename fetal.week21_22.left.Sulc_Wrapsphere.reg.surf.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wrapsphere.reg.surf.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wrap.sphere.reg.surf.gii"

        # # Rename fetal.week21_22.left.Sulc_Wraptransformed_and_reprojected.func.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wraptransformed_and_reprojected.func.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wrap.transformed_and_reprojected.func.gii"

        # # Rename fetal.week21_22.left.Sulc_Wrapsphere.LR.reg.surf.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wrapsphere.LR.reg.surf.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.${side}.Sulc_Wrap.sphere.LR.reg.surf.gii"

        # # Rename fetal.week21_22.left.Sulc_Wrapsphere.reg.surf.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.sphere.reg.surf.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.sphere.reg.surf.gii"

        # # Rename fetal.week21_22.left.Sulc_Wraptransformed_and_reprojected.func.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.transformed_and_reprojected.func.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.transformed_and_reprojected.func.gii"

        # # Rename fetal.week21_22.left.Sulc_Wrapsphere.LR.reg.surf.gii
        # mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.sphere.LR.reg.surf.gii" \
        # "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.sphere.LR.reg.surf.gii"

        # Rename fetal.week21_22.left.Sulc_Wrapsphere.reg.surf.gii
        mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.sphere.reg.surf.gii" \
        "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.sphere.reg.surf.gii" 

        # Rename fetal.week21_22.left.Sulc_Wraptransformed_and_reprojected.func.gii
        mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.transformed_and_reprojected.func.gii" \
        "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.transformed_and_reprojected.func.gii" 

        # Rename fetal.week21_22.left.Sulc_Wrapsphere.LR.reg.surf.gii
        mv "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Curv_Wrap.sphere.LR.reg.surf.gii" \
        "$out_folder/fetal.week${week}_${next_week}.$side.Sulc_Wrap.sphere.LR.reg.surf.gii"

    done
done

# # Rename files in concatenated_registrations directory
# # Loop from 22 to 36
# for week in {21..35}; do
#     for side in left right; do
#         # Rename fetal.weekXX_36.left.Sulc_Wrap.sphere.surf.gii
#         mv "$concat_folder/fetal.week${week}_36.$side.Sulc_Wrap.sphere.surf.gii" \
#         "$concat_folder/fetal.week${week}_36.$side.Sulc_Curv_Wrap.sphere.surf.gii"
#     done
# done


# for week in {21..35}; do
#     for side in left right; do
#         mv "$reprojected_metrics/fetal.week${week}_36.$side.Sulc_Wrap.transformed_and_reprojected.shape.gii" \
#         "$reprojected_metrics/fetal.week${week}_36.$side.Sulc_Curv_Wrap.transformed_and_reprojected.shape.gii"
#     done
# done