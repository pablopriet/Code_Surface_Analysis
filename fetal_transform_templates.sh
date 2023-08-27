#!/bin/bash

# Taking the script name for the usage.
script_name=$(basename "${0}")

# Function to display usage
show_usage() {
    echo -e "Usage: ${script_name} [OPTIONS] <input_file> <output_file>\n"
    echo -e "This script creates concatenated registrations from any given gestational"
    echo    "week template to group level gestational week (36 weeks)"
    echo 
    echo "Arguments:"
    echo "  <atlas_folder>  The path to the folder containing all gestational week templates and corresponding features"
    echo "  <output_folder> The output folder where all the registrations and the corresponding concatenations, and resampled features will be saved"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit."
    echo "  -v, --verbose   Enable verbose mode."
    echo "  -t, --type      Specify the processing type (default: 'basic')."
    echo
    echo "Examples:"
    echo "  ${script_name} /path/to/atlas_folder /path/to/output_folder"
    echo "  ${script_name} -v /path/to/atlas_folder /path/to/output_folder"
}

log_verbose() {
    if [ "$verbose" = true ]; then
        echo "[INFO] $@"
    fi
}

# ------------------------------------------------------------------------------
#        Checking for necessary tools: FSL/msm, wb_command (workbench)
# ------------------------------------------------------------------------------

wb_command_path=$(which wb_command 2>/dev/null)
if [ -z "$wb_command_path" ]; then
    echo "${script_name}:  wb_command (workbench) is not found. Please ensure it is installed."
fi
echo $wb_command_path

msm_path=$(which msm 2>/dev/null)
if [ -z "$msm_path" ]; then
    echo "${script_name}:  msm is not found. Please ensure it is installed."
fi

# Argument parsing
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case $1 in
        -v | --verbose)
            verbose=true
            ;;
        -t | --type)
            shift
            processing_type=$1
            ;;
    esac
    shift
done
if [[ "$1" == '--' ]]; then shift; fi

# Remaining arguments after options are considered as atlas_folder and output_folder
atlas_folder=$1
output_folder=$2

# Check if no arguments were passed or if help is requested, and output usage
if  [ "$#" -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
    exit 0
fi

# ------------------------------------------------------------------------------
#                           Multimodal Surface Matching 
# ------------------------------------------------------------------------------


for start_week in {21..36}; do
    let "next_week=start_week+1"
    for side in left right; do
        # Saving each of the files into variables
        inmesh_file="$atlas_folder/fetal.week$start_week.$side.sphere.surf.gii"
        refmesh_file="$atlas_folder/fetal.week$next_week.$side.sphere.surf.gii"
        indata_file="$atlas_folder/fetal.week$start_week.$side.sulc.shape.gii"
        refdata_file="$atlas_folder/fetal.week$next_week.$side.sulc.shape.gii"
        out_file="$output_folder/fetal.week${start_week}_${next_week}.$side.Sulc_Wrap"
        
        echo "$out_file.gii"
        # Checking if the output file already exists
        if [[ -f "${out_file}.sphere.reg.surf.gii" ]]; then
            echo "Output file for Week $start_week to $next_week, Side $side already exists. Skipping this iteration."
            continue
        fi

        # Checking if files exist
        if [[ ! -f "$inmesh_file" || ! -f "$refmesh_file" || ! -f "$indata_file" || ! -f "$refdata_file" ]]; then
            echo "Warning: One or more files for Week $start_week, Week $next_week, Side $side are missing. Skipping this iteration."
            continue
        fi

        log_verbose "Multimodal Surface Matching between Gestational Week $start_week $side side and Gestational Week $next_week $side side"
         
        $msm_path --inmesh=$inmesh_file --refmesh=$refmesh_file --indata=$indata_file --refdata=$refdata_file --out=$out_file

    done
done

# ------------------------------------------------------------------------------
#                         Registration Concatenation
# ------------------------------------------------------------------------------

# Define the new directory for concatenated registrations
concatenated_folder="$output_folder/concatenated_registrations"

log_verbose "Creating concatenated_folder directory, where concatenated registrations will be outputed"
# Create the directory if it doesn't exist
mkdir -p "$concatenated_folder"

# Copy the initial transform file to the new directory
for side in left right; do
    cp "$output_folder/fetal.week35_36.$side.Sulc_Wrap.sphere.reg.surf.gii" "$concatenated_folder/"
done

for i in {35..22}; do
    for side in left right; do
        let "i_previous=i-1"
        echo "$i $i_previous"
        # Saving each of the files into variables
        in_sphere_file="$output_folder/fetal.week${i_previous}_${i}.$side.Sulc_Wrap.sphere.reg.surf.gii" # 34-35 , 33-34, 32-33    -- 21-22
        sphere_project_to="$atlas_folder/fetal.week${i}.$side.sphere.surf.gii"                           #    35,     34,    33    --    22  
        # Conditional check to determine the directory for sphere_unproject_to                           #    35-36,  34-36, 33-36 --    22-36
        if [[ $i -eq 35 ]]; then                                                                        #Out:   34-36   33-36 32-36        21-36
            sphere_unproject_to="$output_folder/fetal.week${i}_36.$side.Sulc_Wrap.sphere.reg.surf.gii"
        else
            sphere_unproject_to="$concatenated_folder/fetal.week${i}_36.$side.Sulc_Wrap.sphere.surf.gii"
        fi    
        # now it needs to be accessed the unproject to from the concatenated folder
        sphere_out="$concatenated_folder/fetal.week${i_previous}_36.$side.Sulc_Wrap.sphere.surf.gii"  
    
        log_verbose "Concatenating Registrations from gestational week $i $side side to gestational week 36 $side side"

        wb_command -surface-sphere-project-unproject $in_sphere_file $sphere_project_to $sphere_unproject_to $sphere_out
    done
done

# ------------------------------------------------------------------------------
#               Resampling metrics (concatenations) to output sphere
# ------------------------------------------------------------------------------

# Define the new directory for concatenated registrations
reprojected_metrics="$output_folder/reprojected_metrics"

log_verbose "Creating reprojected_metrics directory, where resampled metrics will be outputed"
# Create the directory if it doesn't exist
mkdir -p "$reprojected_metrics"

# Copy the initial transform file to the new directory
for side in left right; do
    cp "$output_folder/fetal.week35_36.$side.Sulc_Wrap.transformed_and_reprojected.func.gii" "$reprojected_metrics/"
done

for i in {35..21}; do
    for side in left right; do

        in_metric="$atlas_folder/fetal.week${i}.$side.sulc.shape.gii"              
        sphere_out="$concatenated_folder/fetal.week${i}_36.$side.Sulc_Wrap.sphere.surf.gii"
        new_sphere="$atlas_folder/fetal.week36.$side.sphere.surf.gii"
        current_area="$atlas_folder/fetal.week${i}.$side.midthickness.surf.gii"
        new_area="$atlas_folder/fetal.week36.$side.midthickness.surf.gii"
        out_metric="$reprojected_metrics/fetal.week${i}_36.$side.Sulc_Wrap.transformed_and_reprojected.shape.gii"
        
        log_verbose "Resampling metrics from gestational week $i to sphere $next_week"
        
        wb_command -metric-resample $in_metric $sphere_out $new_sphere ADAP_BARY_AREA -area-surfs $current_area $new_area $out_metric
    done
done