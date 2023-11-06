#!/bin/ksh

set -x

mkdir -p $DATA/logs
export LOGDIR=$DATA/plots/logs
export LOGDIR_headline=$DATA/plots_headline/logs
export LOGFIN=$DATA/logs
mkdir -p ${LOGFIN}
export STATDIR=$DATA/stats
export PLOTDIR=$DATA/plots
export PLOTDIR_headline=$DATA/plots_headline
export OUTDIR=$DATA/out
export PRUNEDIR=$DATA/prune
mkdir -p $STATDIR
mkdir -p ${PLOTDIR}
mkdir -p $PRUNEDIR
mkdir -p $OUTDIR

model1=`echo $MODELNAME | tr a-z A-Z`
export model1

STARTDATE=${PLOT_START}"00"
ENDDATE=${PLOT_END}"00"

for aqmtyp in ozone pm25 ozmax8 pmave; do
    for biasc in raw bc; do
        DATE=${STARTDATE}
        while [ ${DATE} -le ${ENDDATE} ]; do
            echo ${DATE} > curdate
            DAY=`cut -c 1-8 curdate`
            YEAR=`cut -c 1-4 curdate`
            MONTH=`cut -c 1-6 curdate`
            HOUR=`cut -c 9-10 curdate`

            cpfile=evs.stats.${COMPONENT}_${biasc}.${RUN}.${VERIF_CASE}_${aqmtyp}.v${DAY}.stat
            if [ -e ${EVSINaqm}.${DAY}/${cpfile} ]; then
                cp ${EVSINaqm}.${DAY}/${cpfile} $STATDIR
                sed "s/$model1/${aqmtyp}_${biasc}/g" $STATDIR/${cpfile} > $STATDIR/evs.stats.${aqmtyp}_${biasc}.${RUN}.${VERIF_CASE}.v${DAY}.stat
            else
                echo "WARNING ${COMPONENT} ${STEP} :: Can not find ${EVSINaqm}.${DAY}/${cpfile}"
            fi
            DATE=$(${NDATE} +24 ${DATE})
        done
    done
done

## for region in CONUS CONUS_East CONUS_West CONUS_South CONUS_Central Appalachia CPlains DeepSouth GreatBasin GreatLakes Mezquital MidAtlantic NorthAtlantic NPlains NRockies PacificNW PacificSW Prairie Southeast Southwest SPlains SRockies; do
for region in CONUS_East; do
    export region
    case ${region} in
        CONUS) smregion=conus;;
        CONUS_East) smregion=conus_e;;
        CONUS_West) smregion=conus_w;;
        CONUS_South) smregion=conus_s;;
        CONUS_Central) smregion=conus_c;;
        Appalachia) smregion=apl;;
        CPlains) smregion=cpl;;
        DeepSouth) smregion=ds;;
        GreatBasin) smregion=grb;;
        GreatLakes) smregion=grlk;;
        Mezquital) smregion=mez;;
        MidAtlantic) smregion=matl;;
        NorthAtlantic) smregion=ne;;
        NPlains) smregion=npl;;
        NRockies) smregion=nrk;;
        PacificNW) smregion=npw;;
        PacificSW) smregion=psw;;
        Prairie) smregion=pra;;
        Southeast) smregion=se;;
        Southwest) smregion=sw;;
        SPlains) smregion=spl;;
        SRockies) smregion=srk;;
        *) smregion="nodefinition";;
    esac

    #
    ## for inithr in 06 12; do
    ##     for fcstday in day1 day2 day3; do
    for inithr in 12; do
        for fcstday in day2; do
            case ${fcstday} in
                day1)
                     if [ "${inithr}" == "06" ]; then export flead="22"; fi
                     if [ "${inithr}" == "12" ]; then export flead="16"; fi;;
                day2)
                     if [ "${inithr}" == "06" ]; then export flead="46"; fi
                     if [ "${inithr}" == "12" ]; then export flead="40"; fi;;
                day3)
                     if [ "${inithr}" == "06" ]; then export flead="70"; fi
                     if [ "${inithr}" == "12" ]; then export flead="64"; fi;;
                *)   export flead="40";;
            esac
# Plots for daily 24-hr average PM2.5

            export flead
            export inithr
            export var=PMAVE
            mkdir -p ${COMOUTplots}/${var}
            export lev=A23
            export lev_obs=A1
            export linetype=CTC
            smlev=`echo $lev | tr A-Z a-z`
            smvar=`echo ${var} | tr A-Z a-z`

            cppng=evs.${COMPONENT}.ctc.${smvar}.${smlev}.last31days.csi_by_threshold_init${inithr}z_f${flead}.buk_${smregion}.png
            if [ ! -e ${cppng} ]; then
                $PARMevs/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}/py_plotting_pmave_csi_threshold.config
                export err=$?; err_chk
                cat $LOGDIR/*out
                mv $LOGDIR/*out $LOGFIN
            else
                echo "RESTART - plot exists; copying over to plot directory"
                cp ${COMOUTplots}/${var}/${cppng} ${PLOTDIR}
            fi

            if [ -e ${PLOTDIR}/aq/*/evs*png ]; then
                mv ${PLOTDIR}/aq/*/evs*png ${PLOTDIR}/${cppng}
                cp ${PLOTDIR}/${cppng} ${COMOUTplots}/${var}
		scp ${PLOTDIR}/${cppng} hchuang@rzdm:/home/people/emc/www/htdocs/mmb/hchuang/ftp
            elif [ ! -e ${PLOTDIR}/${cppng} ]; then
                echo "WARNING: NO PLOT FOR",${var},${region}
            fi
        done
    done
done

if [ 1 -eq 2 ]; then

cd ${PLOTDIR}
tar -cvf evs.plots.${COMPONENT}.${RUN}.${VERIF_CASE}.last31days.v${VDATE}.tar *png

if [ $SENDCOM = "YES" ]; then
 mkdir -m 775 -p ${COMOUTplots}
 cp evs.plots.${COMPONENT}.${RUN}.${VERIF_CASE}.last31days.v${VDATE}.tar ${COMOUTplots}
fi

if [ $SENDDBN = YES ] ; then     
 $DBNROOT/bin/dbn_alert MODEL EVS_RZDM $job ${COMOUTplots}/evs.plots.${COMPONENT}.${RUN}.${VERIF_CASE}.last31days.v${VDATE}.tar
fi

fi

exit
