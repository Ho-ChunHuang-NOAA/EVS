#!/bin/ksh
#######################################################################
##  UNIX Script Documentation Block
##                      .
## Script name:         exevs_aqmv7sp_stats.sh
## Script description:  Perform MetPlus PointStat of Air Quality Model.
## Original Author   :  Perry Shafran
##
##   Change Logs:
##
##   04/26/2023   Ho-Chun Huang  modification for using AirNOW ASCII2NC
##   05/22/2023   Ho-Chun Huang  separate hourly ozone by model verified time becasuse
##                               of directory path depends on model verified hour.
##   10/31/2023   Ho-Chun Huang  Update EVS model input directory structure from AQMv6 to AQMv7
##   11/14/2023   Ho-Chun Huang  Replace cp with cpreq
##
##
#######################################################################
#
set -x

mkdir -p ${DATA}/logs
mkdir -p ${DATA}/stat
export finalstat=${DATA}/final
mkdir -p ${DATA}/final

export conf_file_dir=${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}
#######################################################################
# Define INPUT OBS DATA TYPE for PointStat
#######################################################################
#
if [ "${airnow_hourly_type}" == "aqobs" ]; then
  export HOURLY_INPUT_TYPE=hourly_aqobs
else
  export HOURLY_INPUT_TYPE=hourly_data
fi

export dirname=aqm
export gridspec=793
export fcstmax=72
#
## export MASK_DIR is declared in the ~/EVS/jobs/JEVS_AQM_STATS 
#
export model1=`echo ${MODELNAME} | tr a-z A-Z`
echo ${model1}

# Begin verification of both the hourly data of ozone and PM
#
# The valid time of forecast model output is the reference here in PointStat
# Because of the valid time definition between forecat output and observation is different
#     For average concentration of a period [ vhr-1 to vhr ], aqm output is defined at vhr Z
#     while observation is defined at vhr-1 Z
# Thus, the one hour back OBS input will be checked and used in PointStat
#     [OBS_POINT_STAT_INPUT_TEMPLATE=****_{valid?fmt=%Y%m%d%H?shift=-3600}.nc]
#
cdate=${VDATE}${vhr}
vld_date=$(${NDATE} -1 ${cdate} | cut -c1-8)
vld_time=$(${NDATE} -1 ${cdate} | cut -c1-10)

VDAYm1=$(${NDATE} -24 ${cdate} | cut -c1-8)
VDAYm2=$(${NDATE} -48 ${cdate} | cut -c1-8)
VDAYm3=$(${NDATE} -72 ${cdate} | cut -c1-8)

check_file=${EVSINaqm}/${RUN}.${vld_date}/${MODELNAME}/airnow_${HOURLY_INPUT_TYPE}_${vld_time}.nc
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

for outtyp in awpozcon pm25; do
  export outtyp
  cap_outtyp=`echo ${outtyp} | tr a-z A-Z`
    
  case ${outtyp} in
      awpozcon) point_stat_conf_file=PointStat_fcstOZONE_obsAIRNOW_${fcst_input_ver}.conf
                stat_analysis_conf_file=StatAnalysis_fcstOZONE_obsAIRNOW_GatherByDay.conf
                stat_output_index=ozone;;
      pm25)     point_stat_conf_file=PointStat_fcstPM2p5_obsAIRNOW_${fcst_input_ver}.conf
                stat_analysis_conf_file=StatAnalysis_fcstPM_obsANOWPM_GatherByDay.conf
                stat_output_index=pm25;;
  esac

  # Verification to be done both on raw output files and bias-corrected files
    
  for biastyp in raw bc; do
    export biastyp
    
    if [ ${biastyp} = "raw" ]; then
      export bctag=
    elif [ ${biastyp} = "bc" ]; then
      export bctag="_${biastyp}"
    fi
    export bcout="_${biastyp}"
    
    # check to see that model files exist, and list which forecast hours are to be used
    #
    # AQMv7 does not output IC, i.e., f000.  Thus the forecast file will be chekced from f001 to f072
    #
    for hour in 06 12; do
      export hour
      export mdl_cyc=${hour}

      let ihr=1
      num_fcst_in_metplus=0
      recorded_temp_list=${DATA}/fcstlist_in_metplus
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
          fcst_file=${COMINaqm}/${dirname}.${aday}/aqm.t${acyc}z.${outtyp}${bctag}.f${filehr}.${gridspec}.grib2
          if [ -s ${fcst_file} ]; then
            echo "${fhr} found"
            echo ${fhr} >> ${recorded_temp_list}
            let "num_fcst_in_metplus=num_fcst_in_metplus+1"
          else
            if [ $SENDMAIL = "YES" ]; then
              export subject="t${acyc}z ${outtyp}${bctag} AQM Forecast Data Missing for EVS ${COMPONENT}"
              echo "WARNING: No AQM ${outtyp}${bctag} forecast was available for ${aday} t${acyc}z" > mailmsg
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
      export fcsthours_list=`awk -v d=", " '{s=(NR==1?s:s d)$0}END{print s}' ${recorded_temp_list}`
      export num_fcst_in_metplus
      if [ -e ${recorded_temp_list} ]; then rm -f ${recorded_temp_list}; fi
      echo "number of fcst lead in_metplus point_stat for ${outtyp}${bctag} == ${num_fcst_in_metplus}"
    
      if [ ${num_fcst_in_metplus} -gt 0 -a ${obs_hourly_found} -eq 1 ]; then
        export fcsthours=${fcsthours_list}
        run_metplus.py ${conf_file_dir}/${point_stat_conf_file} ${PARMevs}/metplus_config/machine.conf
        export err=$?; err_chk
      else
        echo "WARNING: NO ${cap_outtyp} FORECAST OR OBS TO VERIFY"
        echo "WARNING: NUM FCST=${num_fcst_in_metplus}, INDEX OBS=${obs_hourly_found}"
      fi
    done   ## hour loop
    mkdir -p ${COMOUTsmall}
    if [ ${SENDCOM} = "YES" ]; then
      cpdir=${DATA}/point_stat/${MODELNAME}
      stat_file_count=$(find ${cpdir} -name "*${outtyp}${bcout}*" | wc -l)
      if [ ${stat_file_count} -ne 0 ]; then cpreq ${cpdir}/*${outtyp}${bcout}* ${COMOUTsmall}; fi
    fi
    if [ "${vhr}" == "23" ]; then
      mkdir -p ${COMOUTfinal}
      stat_file_count=$(find ${COMOUTsmall} -name "*${outtyp}${bcout}*" | wc -l)
      if [ ${stat_file_count} -ne 0 ]; then cpreq ${COMOUTsmall}/*${outtyp}${bcout}* ${finalstat}; fi
      cd ${finalstat}
      run_metplus.py ${conf_file_dir}/${stat_analysis_conf_file} ${PARMevs}/metplus_config/machine.conf
      export err=$?; err_chk
      if [ ${SENDCOM} = "YES" ]; then
        cpfile=${finalstat}/evs.${STEP}.${COMPONENT}${bcout}.${RUN}.${VERIF_CASE}_${stat_output_index}.v${VDATE}.stat
        if [ -e ${cpfile} ]; then cpreq ${cpfile} ${COMOUTfinal}; fi
      fi
    fi
  done  ## biastyp loop
done  ## outtyp loop

# Daily verification of the daily maximum of 8-hr ozone
# Verification being done on both raw and bias-corrected output data

check_file=${EVSINaqm}/${RUN}.${VDATE}/${MODELNAME}/airnow_daily_${VDATE}.nc
obs_daily_found=0
if [ -s ${check_file} ]; then
  obs_daily_found=1
else
  echo "WARNING: Can not find pre-processed obs daily input ${check_file}"
  if [ $SENDMAIL = "YES" ]; then
    export subject="AQM Daily Observed Missing for EVS ${COMPONENT}"
    echo "WARNING: No AQM Daily Observed file was available for ${VDATE}" > mailmsg
    echo "Missing file is ${check_file}" >> mailmsg
    echo "Job ID: $jobid" >> mailmsg
    cat mailmsg | mail -s "$subject" $MAILTO
  fi
fi
echo "Index of daily obs found = ${obs_daily_found}"


if [ ${vhr} = 11 ]; then

  export outtyp=OZMAX8
  point_stat_conf_file=PointStat_fcstOZONEMAX_obsAIRNOW_${fcst_input_ver}.conf
  stat_analysis_conf_file=StatAnalysis_fcstOZONEMAX_obsAIRNOW_GatherByDay.conf

  fcstmax=48

  for biastyp in raw bc; do
    export biastyp

    if [ ${biastyp} = "raw" ]; then
      export bctag=
    elif [ ${biastyp} = "bc" ]; then
      export bctag="_${biastyp}"
    fi
    export bcout="_${biastyp}"

    for hour in 06 12; do
      export hour
      export mdl_cyc=${hour}

      ##  search for processed daily 8-hr ozone max model files

      num_fcst_ozmax8=0
      for chk_date in ${VDAYm1} ${VDAYm2} ${VDAYm3}; do
        ozmax8_preprocessed_file=${EVSINaqm}/atmos.${chk_date}/aqm/aqm.t${hour}z.max_8hr_o3${bctag}.${gridspec}.grib2
        if [ -s ${ozmax8_preprocessed_file} ]; then
          let "num_fcst_ozmax8=num_fcst_ozmax8+1"
        else
          if [ $SENDMAIL = "YES" ]; then
            export subject="ozmax8${bctag} AQM Daily Forecast Data Missing for EVS ${COMPONENT}"
            echo "WARNING: No AQM ozmax8${bctag} daily forecast was available for ${chk_date} t${hour}z" > mailmsg
            echo "Missing file is ${ozmax8_preprocessed_file}" >> mailmsg
            echo "Job ID: $jobid" >> mailmsg
            cat mailmsg | mail -s "$subject" $MAILTO
          fi
          echo "WARNING: No AQM max_8hr_o3${bctag} forecast was available for ${chk_date} t${hour}z"
          echo "WARNING: Missing file is ${ozmax8_preprocessed_file}"
        fi
      done
      echo "number of fcst day for ${outtyp}${bctag} == ${num_fcst_ozmax8}, index of daily obs_found == ${obs_daily_found}"
      if [ ${num_fcst_ozmax8} -gt 0 -a ${obs_daily_found} -gt 0 ]; then 
        run_metplus.py ${conf_file_dir}/${point_stat_conf_file} ${PARMevs}/metplus_config/machine.conf
        export err=$?; err_chk
      else
        echo "WARNING: NO OZMAX8 OBS OR MODEL DATA"
        echo "WARNING: NUM FCST=${num_fcst_ozmax8}, INDEX OBS=${obs_daily_found}"
      fi
    done   ## hour loop
    if [ ${SENDCOM} = "YES" ]; then
      cpdir=${DATA}/point_stat/${MODELNAME}
      stat_file_count=$(find ${cpdir} -name "*${outtyp}${bcout}*" | wc -l)
      if [ ${stat_file_count} -ne 0 ]; then cpreq ${cpdir}/*${outtyp}${bcout}* ${COMOUTsmall}; fi
    fi
    stat_file_count=$(find ${COMOUTsmall} -name "*${outtyp}${bcout}*" | wc -l)
    if [ ${stat_file_count} -ne 0 ]; then cpreq ${COMOUTsmall}/*${outtyp}${bcout}* ${finalstat}; fi
    run_metplus.py ${conf_file_dir}/${stat_analysis_conf_file} ${PARMevs}/metplus_config/machine.conf
    export err=$?; err_chk
    if [ ${SENDCOM} = "YES" ]; then
      cpfile=${finalstat}/evs.${STEP}.${COMPONENT}${bcout}.${RUN}.${VERIF_CASE}_ozmax8.v${VDATE}.stat
      if [ -e ${cpfile} ]; then cpreq ${cpfile} ${COMOUTfinal}; fi
    fi
  done  ## biastyp loop
fi  ## vhr if logic

# Daily verification of the daily average of PM2.5
# Verification is being done on both raw and bias-corrected output data

if [ ${vhr} = 04 ]; then

  export outtyp=PMAVE
  point_stat_conf_file=PointStat_fcstPMAVE_obsANOWPM_${fcst_input_ver}.conf
  stat_analysis_conf_file=StatAnalysis_fcstPMAVE_obsANOWPM_GatherByDay.conf

  fcstmax=48
  for biastyp in raw bc; do
    export biastyp
    echo ${biastyp}

    if [ ${biastyp} = "raw" ]; then
      export bctag=
    elif [ ${biastyp} = "bc" ]; then
      export bctag="_${biastyp}"
    fi
    export bcout="_${biastyp}"

    for hour in 06 12; do
      export hour
      export mdl_cyc=${hour}

      ##  search for forecast daily average PM model files

      num_fcst_pmave=0
      for chk_date in ${VDAYm1} ${VDAYm2} ${VDAYm3}; do
        fcst_file=${COMINaqm}/${dirname}.${chk_date}/aqm.t${hour}z.ave_24hr_pm25${bctag}.${gridspec}.grib2
        if [ -s ${fcst_file} ]; then
          let "num_fcst_pmave=num_fcst_pmave+1"
        else
          if [ $SENDMAIL = "YES" ]; then
            export subject="t${hour}z PMAVE${bctag} AQM Forecast Data Missing for EVS ${COMPONENT}"
            echo "WARNING: No AQM ave_24hr_pm25${bctag} forecast was available for ${chk_date} t${hour}z" > mailmsg
            echo "Missing file is $fcst_file}" >> mailmsg
            echo "Job ID: $jobid" >> mailmsg
            cat mailmsg | mail -s "$subject" $MAILTO
          fi

          echo "WARNING: No AQM ave_24hr_pm25${bctag} forecast was available for ${chk_date} t${hour}z"
          echo "WARNING: Missing file is $fcst_file}"
        fi
      done
      echo "number of fcst day for ${outtyp}${bctag} == ${num_fcst_pmave} index of daily obs_found == ${obs_daily_found}"

      if [ ${num_fcst_pmave} -gt 0 -a ${obs_daily_found} -gt 0 ]; then
        run_metplus.py ${conf_file_dir}/${point_stat_conf_file} ${PARMevs}/metplus_config/machine.conf
        export err=$?; err_chk
      else
        echo "WARNING: NO PMAVE OBS OR MODEL DATA"
        echo "WARNING: NUM FCST=${num_fcst_pmave}, INDEX OBS=${obs_daily_found}"
      fi
    done   ## hour loop
    if [ ${SENDCOM} = "YES" ]; then
      cpdir=${DATA}/point_stat/${MODELNAME}
      stat_file_count=$(find ${cpdir} -name "*${outtyp}${bcout}*" | wc -l)
      if [ ${stat_file_count} -ne 0 ]; then cpreq ${cpdir}/*${outtyp}${bcout}* ${COMOUTsmall}; fi
    fi
    stat_file_count=$(find ${COMOUTsmall} -name "*${outtyp}${bcout}*" | wc -l)
    if [ ${stat_file_count} -ne 0 ]; then cpreq ${COMOUTsmall}/*${outtyp}${bcout}* ${finalstat}; fi
    run_metplus.py ${conf_file_dir}/${stat_analysis_conf_file} ${PARMevs}/metplus_config/machine.conf
    export err=$?; err_chk
    if [ ${SENDCOM} = "YES" ]; then
      cpfile=${finalstat}/evs.${STEP}.${COMPONENT}${bcout}.${RUN}.${VERIF_CASE}_pmave.v${VDATE}.stat
      if [ -e ${cpfile} ]; then cpreq ${cpfile} ${COMOUTfinal}; fi
    fi
  done  ## biastyp loop
fi  ## vhr if logic

exit

