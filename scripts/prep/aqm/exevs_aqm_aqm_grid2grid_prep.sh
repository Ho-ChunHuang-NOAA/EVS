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
##   09/30/2024   Ho-Chun Huang  modify for GOES-EAST/WEST and SCAN-MODE
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
export OBSTYPE=$(echo ${DATA_TYPE} | tr a-z A-Z)    # config variable

#
conf_dir=${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}
config_file=Point2Grid_hourly_obs${OBSTYPE}.conf
config_common=${PARMevs}/metplus_config/machine.conf
 
export dirname=aqm
export gridspec=793

export CMODEL=$(echo ${MODELNAME} | tr a-z A-Z)
echo ${CMODEL}

export jday=$(date2jday.sh ${VDATE})        # need module load prod_util

grid2grid_list="${DATA_TYPE}"

satellite_list="${satellite_name}"

goes_scan_list="${AOD_SCAN_TYPE}"

export output_var="aod"
export VARID=$(echo ${output_var} | tr a-z A-Z)    # config variable

# AOD quality flag 0:high 1:medium 3:low 0,1: high+medium,...etc
if [ "${AOD_QC_NAME}" == "high" ]; then   # high quality AOD only
    export AOD_QC_FLAG="0"    # config variable
elif [ "${AOD_QC_NAME}" == "medium" ]; then   # high+medium quality AOD
    export AOD_QC_FLAG="0,1"    # config variable
else
    echo "AOD quality usage = ${AOD_QC_NAME} is not defined, use high as default"
    export AOD_QC_NAME="high"    # config variable
    export AOD_QC_FLAG="0"    # config variable
fi

num_mdl_grid=0
declare -a cyc_opt=( 06 12 )
for mdl_cyc in "${cyc_opt[@]}"; do
    let ic=1
    let endvhr=72
    while [ ${ic} -le ${endvhr} ]; do
        filehr=$(printf %3.3d ${ic})
        checkfile=${COMINaqm}/${dirname}.${VDATE}/${mdl_cyc}/${MODELNAME}.t${mdl_cyc}z.cmaq.f${filehr}.${gridspec}.grib2
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
  for ObsType in ${grid2grid_list}; do
    export ObsType
    export OBSTYPE=`echo ${ObsType} | tr a-z A-Z`    # config variable

    for SatId in ${satellite_list}; do
      export SatId
      export SATID=$(echo ${SatId} | tr a-z A-Z)    # config variable

      for AOD_SCAN in ${goes_scan_list}; do
        export AOD_SCAN
        export Aod_Scan=$(echo ${AOD_SCAN} | tr A-Z a-z)    # config variable

        export RUNTIME_PREP_DIR=${DATA}/prepsave/${ObsType}_${SatId}_${Aod_Scan}_${AOD_QC_NAME}_${VDATE}
        mkdir -p ${RUNTIME_PREP_DIR}

        let ic=0
        let endvhr=23
        while [ ${ic} -le ${endvhr} ]; do
            vldhr=$(printf %2.2d ${ic})
            checkfile="OR_${OBSTYPE}-L2-${AOD_SCAN}-M*_${SATID}_s${jday}${vldhr}*.nc"
            obs_file_count=$(find ${DCOMINabi}/GOES_${AOD_SCAN} -name ${checkfile} | wc -l )
            if [ ${obs_file_count} -ne 0 ]; then
                export VHOUR=${vldhr}    # config variable
                ## ls ${DCOMINabi}/GOES_${ADP_SCAN}/${checkfile} > all_hourly_adp_file
                ## export filein_adp=$(head -n1 all_hourly_adp_file)    # config variable
                ls ${DCOMINabi}/GOES_${AOD_SCAN}/${checkfile} > all_hourly_aod_file
                export filein_aod=$(head -n1 all_hourly_aod_file)    # config variable
                if [ -s ${conf_dir}/${config_file} ]; then
                    export out_file_prefix=${ObsType}_${AOD_SCAN}_${MODELNAME}_${SatId}
                    run_metplus.py ${conf_dir}/${config_file} ${config_common}
                    ## out_file=${RUNTIME_PREP_DIR}/${out_file_prefix}_${VDATE}_${VHOUR}_${AOD_QC_NAME}.nc
                    ## point2grid ${filein_aod} ${filein_mdl_grid} ${out_file} -field 'name="AOD"; level="(*,*)";' -method UW_MEAN -v 2 -qc ${AOD_QC_FLAG}
                    export err=$?; err_chk
                    if [ ${SENDCOM} = "YES" ]; then
                        cpfile=${RUNTIME_PREP_DIR}/${out_file_prefix}_${VDATE}_${VHOUR}_${AOD_QC_NAME}.nc
                        if [ -s ${cpfile} ]; then cp -v ${cpfile} ${COMOUTproc}; fi
                    fi
                else
                    echo "WARNING: can not find ${conf_dir}/${config_file}"
                fi
            else
                if [ ${SENDMAIL} = "YES" ]; then
                    export subject="${OBSTYPE} ${SATID} ${AOD_SCAN} Hourly Data Missing for EVS ${COMPONENT}"
                    echo "WARNING: No ${OBSTYPE} ${SATID} ${AOD_SCAN} was avaiable valid ${VDATE}${vldhr}" > mailmsg
                    echo "Missing file is ${checkfile}" >> mailmsg
                    echo "Job ID: $jobid" >> mailmsg
                    cat mailmsg | mail -s "$subject" $MAILTO 
                fi
    
                echo "WARNING: No ${OBSTYPE} ${SATID} ${AOD_SCAN} was avaiable valid ${VDATE}${vldhr}"
                echo "WARNING: Missing file is ${checkfile}"
            fi
            ((ic++))
        done  # vldhr
      done  # AOD_SCAN
    done  # SatId
  done  # ObsType
else
    if [ ${SENDMAIL} = "YES" ]; then
        export subject="${MODELNAME} ${VARID} NC Output Missing for EVS ${COMPONENT}"
        echo "WARNING: No ${MODELNAME} ${VARID} NC output was avaiable valid ${VDATE}" > mailmsg
        echo "Missing file is ${checkfile}" >> mailmsg
        echo "Job ID: $jobid" >> mailmsg
        cat mailmsg | mail -s "$subject" $MAILTO 
    fi

    echo "WARNING: No AIRNOW ASCII data was available for valid date ${VDATE}"
    echo "WARNING: Missing file is ${checkfile}"
fi

if [ 1 -eq 2 ]; then   ## keep for future one email format
    if [ ${SENDMAIL} = "YES" ]; then
        export subject="${MODELNAME} ${AOD_SCAN} NC Output Missing for EVS ${COMPONENT}"
        echo "WARNING: No ${MODELNAME} ${AOD_SCAN} NC output was avaiable valid ${VDATE}" > mailmsg
        echo "Job ID: $jobid" >> mailmsg
        cat mailmsg | mail -s "$subject" $MAILTO 
    fi

    echo "WARNING: No ${MODELNAME} ${AOD_SCAN} grid2 output was avaiable valid ${VDATE}"
fi
exit

