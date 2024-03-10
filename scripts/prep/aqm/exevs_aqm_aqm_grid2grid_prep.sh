#!/bin/bash
#######################################################################
##  UNIX Script Documentation Block
##                      .
## Script name:         exevs_aqm_aqm_grid2grid_prep.sh
## Script description:  Pre-processed input data for the MetPlus GridStat 
##                      of Air Quality Model.
## Original Author   :  Ho-Chun Huang
##
##   Change Logs:
##
##   02/21/2024   Ho-Chun Huang  modify for AQMv7 verification
##
##
#######################################################################
#
set -x

cd ${DATA}

export config=${PARMevs}/evs_config/${COMPONENT}/config.evs.aqm.prod
source ${config}

#######################################################################
# Define INPUT OBS DATA TYPE for ASCII2NC 
#######################################################################
#
conf_dir=${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}
config_file=Point2Grid_hourly_obs${OBSTYPE}.conf
config_common_=${PARMevs}/metplus_config/machine.conf
 
export dirname=aqm
## export gridspec=793

export RUNTIME_PREP_DIR=${DATA}/prepsave
mkdir -p ${RUNTIME_PREP_DIR}

export CMODEL=$(echo ${MODELNAME} | tr a-z A-Z)
echo ${CMODEL}

export OBSTYPE=$(echo ${DATA_TYPE} | tr a-z A-Z)    # config variable

export jday=$(date2jday.sh ${VDATE})        # need module load prod_util

export satellite_name="g16"
export SATID=$(echo ${satellite_name} | tr a-z A-Z)    # config variable

export output_var="aod"
export VARID=$(echo ${output_var} | tr a-z A-Z)    # config variable

# AOD quality flag 0:high 1:medium 3:low 0,1: high+medium,...etc
export AOD_QC_FLAG="0"    # config variable

num_mdl_grid=0
declare -a cyc_opt=( 06 12 )
for mdl_cyc in "${cyc_opt[@]}"; do
    let ic=1
    let endvhr=72
    while [ ${ic} -le ${endvhr} ]; do
        filehr=$(printf %3.3d ${ic})
        checkfile=${COMINaqm}/${dirname}.${VDATE}/${mdl_cyc}/${MODELNAME}.t${mdl_cyc}z.${output_var}.f${filehr}.grib2
        if [ -s ${checkfile} ]; then
            export filein_mdl_grid=${checkfile}    # config variable
            num_mdl_grid=1
            break
        fi
        ((ic++))
    done
    if [ "${num_mdl_grid}" == "1" ]; then break; fi
done
#
## Pre-Processed GOES ABI high qualtiy AOD for GridStat
#
if [ "${num_mdl_grid}" != "0" ]; then
    let ic=0
    let endvhr=23
    while [ ${ic} -le ${endvhr} ]; do
        vldhr=$(printf %2.2d ${ic})
        checkfile="OR_${OBSTYPE}-L2-${VARID}C-M*_${SATID}-s${jday}${vldhr}*.nc"
        obs_file_count=$(find ${DCOMIN}/${VDATE} -name ${checkfile} | wc -l )
        if [ ${obs_file_count} -ne 0 ]; then
            export VHOUR=${vldhr}    # config variable
            ls ${DCOMIN}/${VDATE}/${checkfile} > all_hourly_aod_file
            export filein_aod=$(head -n1 all_hourly_aod_file)    # config variable
            if [ -s ${conf_dir}/${config_file} ]; then
                run_metplus.py ${conf_dir}/${config_file} ${config_common}
                export err=$?; err_chk
                if [ ${SENDCOM} = "YES" ]; then
                    cpfile=${RUNTIME_PREP_DIR}/${DATA_TYPE}_AOD_${MODELNAME}_${satellite_name}_${VDATE}_${VHOUR}.nc
                    if [ -s ${cpfile} ]; then cp -v ${cpfile} ${COMOUTproc}; fi
                fi
            else
                echo "WARNING: can not find ${conf_dir}/${config_file}"
            fi
        else
            if [ ${SENDMAIL} = "YES" ]; then
                export subject="${OBSTYPE} ${SATID} ${VARID} Hourly Data Missing for EVS ${COMPONENT}"
                echo "WARNING: No ${OBSTYPE} ${SATID} ${VARID} was avaiable valid ${VDATE}${vldhr}" > mailmsg
                echo "Missing file is ${checkfile}" >> mailmsg
                echo "Job ID: $jobid" >> mailmsg
                cat mailmsg | mail -s "$subject" $MAILTO 
            fi
    
            echo "WARNING: No ${OBSTYPE} ${SATID} ${VARID} was avaiable valid ${VDATE}${vldhr}"
            echo "WARNING: Missing file is ${checkfile}"
        fi
        ((ic++))
    done
else
    if [ ${SENDMAIL} = "YES" ]; then
        export subject="AIRNOW ASCII Daily Data Missing for EVS ${COMPONENT}"
        echo "WARNING: No AIRNOW ASCII data was available for valid date ${VDATE}" > mailmsg
        echo "Missing file is ${checkfile}" >> mailmsg
        echo "Job ID: $jobid" >> mailmsg
        cat mailmsg | mail -s "$subject" $MAILTO 
    fi

    echo "WARNING: No AIRNOW ASCII data was available for valid date ${VDATE}"
    echo "WARNING: Missing file is ${checkfile}"
fi

log_dir="${DATA}/logs/${CMODEL}"
if [ -d ${log_dir} ]; then
    log_file_count=$(find ${log_dir} -type f | wc -l)
    if [[ ${log_file_count} -ne 0 ]]; then
       log_files=("${log_dir}"/*)
       for log_file in "${log_files[@]}"; do
          if [ -f "${log_file}" ]; then
             echo "Start: ${log_file}"
             cat "${log_file}"
             echo "End: ${log_file}"
          fi
      done
  fi
fi
else
    if [ ${SENDMAIL} = "YES" ]; then
        export subject="${MODELNAME} ${VARID} Grib2 Output Missing for EVS ${COMPONENT}"
        echo "WARNING: No ${MODELNAME} ${VARID} grid2 output was avaiable valid ${VDATE}" > mailmsg
        echo "Job ID: $jobid" >> mailmsg
        cat mailmsg | mail -s "$subject" $MAILTO 
    fi

    echo "WARNING: No ${MODELNAME} ${VARID} grid2 output was avaiable valid ${VDATE}"
fi
exit

