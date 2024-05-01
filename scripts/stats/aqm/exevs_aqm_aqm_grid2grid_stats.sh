#!/bin/bash
#######################################################################
##  UNIX Script Documentation Block
##                      .
## Script name:         exevs_aqm_grid2grid_stats.sh
## Script description:  Perform MetPlus GridStat of Air Quality Model.
##
##   Change Logs:
##
##   04/30/2024   Ho-Chun Huang  modification for using GOES-16 AOD
##
##   Note :  The lead hours specification is important to avoid the error generated 
##           by the MetPlus for not finding the input FCST or OBS files. The error
##           will lead to job crash by err_chk.
##
#######################################################################
#
set -x

export config=$PARMevs/evs_config/$COMPONENT/config.evs.aqm.prod
source $config

recorded_temp_list=${DATA}/fcstlist_in_metplus

mkdir -p ${DATA}/logs
mkdir -p ${DATA}/stat
export finalstat=${DATA}/final
mkdir -p ${DATA}/final

export conf_file_dir=${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}
#######################################################################
# Define INPUT OBS DATA TYPE for GridStat
#######################################################################
#
export dirname=aqm
export gridspec=793
export fcstmax=72
#
## export MASK_DIR is declared in the ~/EVS/jobs/JEVS_AQM_STATS 
#
export CMODEL=$(echo ${MODELNAME} | tr a-z A-Z)
echo ${CMODEL}

export CONFIGevs=${CONFIGevs:-${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}}
export config_common=${PARMevs}/metplus_config/machine.conf

grid2grid_list="${DATA_TYPE}"

satellite_list="${SATELLITE_TYPE}"

export vld_cyc="00 06 12 18"

flag_send_message=NO
if [ -e mailmsg ]; then /bin/rm -f mailmsg; fi

for ObsType in ${grid2grid_list}; do
  export ObsType
  case ${ObsType} in
       abi) export obs_var=aod;;
       viirs)  export obs_var=aod;;
   esac

  export RUNTIME_STATS=${DATA}/grid_stat/${MODELNAME}_${ObsType}  # config variable
  export OBSTYPE=`echo ${ObsType} | tr a-z A-Z`    # config variable

  export VARID=$(echo ${obs_var} | tr a-z A-Z)    # config variable

  for satellite_name in ${satellite_list}:
    export satellite_name
    export SATID=$(echo ${satellite_name} | tr a-z A-Z)    # config variable

# Begin verification of both the hourly data of ozone and PM
#
# The valid time of forecast model output is the reference here in GridStat
# Because of the valid time definition between forecat output and observation is different
#     For average concentration of a period [ vhr-1 to vhr ], aqm output is defined at vhr Z
#     while observation is defined at vhr-1 Z
# Thus, the one hour back OBS input will be checked and used in GridStat
#     [OBS_POINT_STAT_INPUT_TEMPLATE=****_{valid?fmt=%Y%m%d%H?shift=-3600}.nc]
#
    check_file=${EVSINaqm}/${RUN}.${VDATE}/${MODELNAME}/${ObsType}_${VARID}_${MODELNAME}_$(satellite_name}_${VDATE}_${vhr}.nc
    obs_hourly_found=0
    if [ -s ${check_file} ]; then
      obs_hourly_found=1
    else
      echo "WARNING: Can not find pre-processed obs hourly input ${check_file}"
      if [ $SENDMAIL = "YES" ]; then 
        export subject="AQM Hourly Observed Missing for EVS ${COMPONENT}"
        echo "WARNING: No AQM ${HOURLY_INPUT_TYPE} was available for ${vld_date} ${vld_time}" > mailmsg
        echo "Missing file is ${check_file}" >> mailmsg
        echo "Job ID: $jobid" >> mailmsg
        cat mailmsg | mail -s "$subject" $MAILTO
      fi
    fi
    echo "index of hourly obs found = ${obs_hourly_found}"

    for outtyp in ${obs_var}; do
      export outtyp
      cap_outtyp=`echo ${outtyp} | tr a-z A-Z`
    
      case ${outtyp} in
           aod) grid_stat_conf_file=GridStat_fcst${cap_outtyp}_obs.{OBSTYPE}conf
                stat_analysis_conf_file=StatAnalysis_fcst${cap_outtyp}_obs{OBSTYPE}_GatherByDay.conf
                export aqm_file_index=cmaq;;
                stat_output_index=aod;;
      esac

      # Verification to be done both on raw output files and bias-corrected files
    
      for biastyp in raw ; do
        export biastyp
    
        if [ ${biastyp} = "raw" ]; then
          export bctag=
        elif [ ${biastyp} = "bc" ]; then
          export bctag="_${biastyp}"
        fi
        export bcout="_${biastyp}"
        export OutputId=${MODELNAME}_${outtyp}${bcout}_${obs_var}            # config variable
        export StatFileId=${NET}.${STEP}.${MODELNAME}${bcout}.${RUN}.${VERIF_CASE}_${ObsType}_${obs_var} # config variable
    
        # check to see that model files exist, and list which forecast hours are to be used
        #
        # AQMv7 does not output IC, i.e., f000.  Thus the forecast file will be chekced from f001 to f072
        #
        for hour in ${vld_cyc}; do
          export hour
          export mdl_cyc=${hour}    ## is needed for *.conf

          let ihr=1
          num_fcst_in_metplus=0
          if [ -e ${recorded_temp_list} ]; then rm -f ${recorded_temp_list}; fi
          while [ ${ihr} -le ${fcstmax} ]; do
            filehr=$(printf %3.3d ${ihr})    ## fhr of grib2 filename is in 3 digit for aqmv7
            fhr=$(printf %2.2d ${ihr})       ## fhr for the processing valid hour is in 2 digit
            export fhr
    
            export datehr=${VDATE}${vhr}
            adate=`${NDATE} -${ihr} ${datehr}`
            aday=`echo ${adate} |cut -c1-8`
            acyc=`echo ${adate} |cut -c9-10`
            if [ ${acyc} = ${hour} ]; then
              fcst_file=${COMINaqm}/${dirname}.${aday}/${acyc}/aqm.t${acyc}z.${aqm_file_index}${bctag}.f${filehr}.${gridspec}.grib2
              if [ -s ${fcst_file} ]; then
                echo "${fhr} found"
                echo ${fhr} >> ${recorded_temp_list}
                let "num_fcst_in_metplus=num_fcst_in_metplus+1"
              else
                if [ $SENDMAIL = "YES" ]; then
                  export subject="t${acyc}z ${aqm_file_index}${bctag} AQM Forecast Data Missing for EVS ${COMPONENT}"
                  echo "WARNING: No AQM ${aqm_file_index}${bctag} forecast was available for ${aday} t${acyc}z" > mailmsg
                  echo "Missing file is ${fcst_file}" >> mailmsg
                  echo "Job ID: $jobid" >> mailmsg
                  cat mailmsg | mail -s "$subject" $MAILTO
                fi

                echo "WARNING: No AQM ${outtyp}${bctag} forecast was available for ${aday} t${acyc}z"
                echo "WARNING: Missing file is ${fcst_file}"
              fi 
            fi 
            ((ihr++))
          done
          if [ -s ${recorded_temp_list} ]; then
            export fcsthours_list=`awk -v d=", " '{s=(NR==1?s:s d)$0}END{print s}' ${recorded_temp_list}`
          fi
          if [ -e ${recorded_temp_list} ]; then rm -f ${recorded_temp_list}; fi
          export num_fcst_in_metplus
          echo "number of fcst lead in_metplus grid_stat for ${outtyp}${bctag} == ${num_fcst_in_metplus}"
    
          if [ ${num_fcst_in_metplus} -gt 0 -a ${obs_hourly_found} -eq 1 ]; then
            export fcsthours=${fcsthours_list}
            run_metplus.py ${conf_file_dir}/${grid_stat_conf_file} ${config_common}
            export err=$?; err_chk
          else
            echo "WARNING: NO ${cap_outtyp} FORECAST OR OBS TO VERIFY"
            echo "WARNING: NUM FCST=${num_fcst_in_metplus}, INDEX OBS=${obs_hourly_found}"
          fi
        done   ## hour loop
        mkdir -p ${COMOUTsmall}
        if [ ${SENDCOM} = "YES" ]; then
          if [ -d ${RUNTIME_STATS} ]; then      ## does not exist if run_metplus.py did not execute
            stat_file_count=$(find ${RUNTIME_STATS} -name "*${OutputId}*" | wc -l)
            if [ ${stat_file_count} -ne 0 ]; then
              mkdir -p ${COMOUTsmall}
              cp -v ${RUNTIME_STATS}/*${OutputId}* ${COMOUTsmall}
            fi
          fi
        fi
        if [ "${vhr}" == "23" ]; then
          mkdir -p ${COMOUTfinal}
          stat_file_count=$(find ${COMOUTsmall} -name "*${OutputId}*" | wc -l)
          if [ ${stat_file_count} -ne 0 ]; then
            cpreq ${COMOUTsmall}/*${OutputId}* ${finalstat}
            cd ${finalstat}
            run_metplus.py ${conf_file_dir}/${stat_analysis_conf_file} ${config_common}
            export err=$?; err_chk
            if [ ${SENDCOM} = "YES" ]; then
              cpfile=${finalstat}/${StatFileId}.v${VDATE}.stat
              if [ -s ${cpfile} ]; then
                mkdir -p ${COMOUTfinal}
                cp -v ${cpfile} ${COMOUTfinal}
              fi
            fi
          fi
        fi
      done  ## biastyp loop
    done  ## outtyp loop
  done  ## satellite_name loop
done  ## ObsType loop


log_dir="$DATA/logs/${model1}"
if [ -d $log_dir ]; then
   log_file_count=$(find $log_dir -type f | wc -l)
   if [[ $log_file_count -ne 0 ]]; then
       log_files=("$log_dir"/*)
       for log_file in "${log_files[@]}"; do
          if [ -f "$log_file" ]; then
             echo "Start: $log_file"
             cat "$log_file"
             echo "End: $log_file"
          fi
      done
  fi
fi

exit

