#!/bin/bash
###############################################################################
# Name of Script: exevs_plots_global_chem_headline_grid2obs.sh
# Developers: Ho-Chun Huang / Ho-Chun.Huang@noaa.gov
#
# Purpose of Script: This script is run for the global_chem plots step for
#                    the headline verification. It uses EMC-developed
#                    python scripts to do the plotting.
#
#   Change Logs:
#    09/02/2025  Ho-Chun Huang    move cpreq to cp -v to comply with EE2
#    10/07/2025   Ho-Chun Huang  Revise code for GCAFSv1 naming and data structure
###############################################################################

set -x

echo "RUN MODE:${evs_run_mode}"

## Provide temporary staging area for renaming and/or updating model
## name id in the stats files
export STATDIR=${DATA}/stats_staging

## Provide input stats location in ~/ush/global_chem/global_chem_plots_headline.py
export linked_stat_base_dir=${DATA}/data/headline

mkdir -p ${STATDIR} ${linked_stat_base_dir}

gcafs_ver_id=$( echo ${gcafs_ver} | awk -F"." '{print $1}' )
export modelid=${MODELNAME}${gcafs_ver_id}
#
# Define the verification variables and observation sources
declare -a obstype_list=("pm25" "pm10" "aod")
declare -a obssrc_list=("airnow" "airnow" "aeronet")

# Define the model names, plot names, and stats directory
declare -a mdl_list=("${modelid}")
declare -a plotname_list=("${gcafs_ver_id}")
declare -a mdl_idir_list=("${COMIN}/stats/${COMPONENT}")

# Define a constant for the maximum number of models
readonly MAX_MODELS=10

# Check if observation arrays have matching lengths
if (( ${#obstype_list[@]} != ${#obssrc_list[@]} )); then
    echo "DEBUG: The number of verification types does not match the number of observation sources."
    exit 1
fi

# Check if the number of models exceeds the maximum limit
if (( ${#mdl_list[@]} > MAX_MODELS )); then
    echo "DEBUG: Number of models to plot cannot exceed ${MAX_MODELS}."
    exit 1
fi

# Check if model and plot name arrays have matching lengths
if (( ${#mdl_list[@]} != ${#plotname_list[@]} )); then
    echo "DEBUG: The number of model IDs does not match the number of names to be plotted."
    exit 1
fi

# Export verification type info
export plot_obstype_list=$(IFS=,; echo "${obstype_list[*]}")

# Export observation source info
export plot_obssrc_list=$(IFS=,; echo "${obssrc_list[*]}")

# Export model info
export plot_model_list=$(IFS=,; echo "${mdl_list[*]}")

# Export plot name info
export plot_plotname_list=$(IFS=,; echo "${plotname_list[*]}")

#
# Bringing in all statistics files and rearranging the filename and
# model ID according to the model name defined in `mdl_list`.
#
for imdl in "${!mdl_list[@]}"; do
    model_name=${mdl_list[${imdl}]}
    linked_plot_stat_dir=${linked_stat_base_dir}/${model_name}
    if [ ! -d ${linked_plot_stat_dir} ]; then mkdir -p ${linked_plot_stat_dir}; fi
    idir=${mdl_idir_list[${imdl}]}
    target_model="${model_name%v[0-9]*}"   ## model name separate by version number started with "v"
    upper_model="${target_model^^}"     ## Upper case model name as in the stats files
    for ivar in "${!obstype_list[@]}"; do
        obsvar=${obstype_list[${ivar}]}
        obssrc=${obssrc_list[${ivar}]}
        ## get 2 additional day's stat for day 1 forecast
        cdate=${VDATE_START}"00"
        NOW=$( ${NDATE} -48 ${cdate} | cut -c1-8 )
        while [ ${NOW} -le ${VDATE_END} ]; do
            cpfile=evs.stats.${target_model}.atmos.${VERIF_CASE}_${obssrc}_${obsvar}.v${NOW}.stat
            sedfile=${model_name}_${obssrc}_${obsvar}.v${NOW}.stat
            if [ -s ${idir}/${target_model}.${NOW}/${cpfile} ]; then
                cp -v ${idir}/${target_model}.${NOW}/${cpfile} ${STATDIR}
                sed "s/${upper_model}/${model_name}/g" ${STATDIR}/${cpfile} > ${STATDIR}/${sedfile}
                dest_model_date_stat_file=${linked_plot_stat_dir}/${model_name}_${obssrc}_${obsvar}_v${NOW}.stat
                ln -s ${STATDIR}/${sedfile} ${dest_model_date_stat_file}
            else
                echo "DEBUG :: Input Stats ${idir}/${target_model}.${NOW}/${cpfile} is missing and the missing file will be skipped"
            fi
            cdate=${NOW}"00"
            NOW=$( ${NDATE} +24 ${cdate} | cut -c1-8 )
        done
    done
done

# Create headline plots
python ${USHevs}/${COMPONENT}/${COMPONENT}_${STEP}_${RUN}.py
export err=$?; err_chk

# Copy files to desired location
if [ "${SENDCOM}" == "YES" ]; then
    # Make and copy tar file
    cd ${DATA}/images
    headline_tar_combine=evs.plots.${COMPONENT}.atmos.${RUN}.v${VDATE_END}.tar
    headline_tar_name=${DATA}/${headline_tar_combine}
    tar -cvf ${headline_tar_name} *.png
    if [ -f "${headline_tar_name}" ]; then
        cp -v ${headline_tar_name} ${COMOUT}/.

        if [ "${SENDDBN}" = "YES" ]; then
            ${DBNROOT}/bin/dbn_alert MODEL EVS_RZDM ${job} ${COMOUT}/${headline_tar_combine}
        fi
    fi
fi
