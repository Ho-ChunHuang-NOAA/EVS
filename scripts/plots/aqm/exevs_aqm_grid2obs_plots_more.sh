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
mkdir -p ${PLOTDIR} ${PLOTDIR_headline}
mkdir -p $PRUNEDIR
mkdir -p $OUTDIR

model1=`echo $MODELNAME | tr a-z A-Z`
export model1

STARTDATE=${VDATE}00
## ENDDATE=${PDYm31}00
ENDDATE=${VDAYm31}00
for aqmtyp in ozone pm25 ozmax8 pmave; do
    for biasc in raw bc; do
        DATE=$STARTDATE
        while [ $DATE -ge $ENDDATE ]; do
            echo $DATE > curdate
            DAY=`cut -c 1-8 curdate`
            YEAR=`cut -c 1-4 curdate`
            MONTH=`cut -c 1-6 curdate`
            HOUR=`cut -c 9-10 curdate`

            cpfile=evs.stats.${COMPONENT}_${biasc}.${RUN}.${VERIF_CASE}_${aqmtyp}.v${DAY}.stat
            if [ -e ${EVSINaqm}.$DAY/${cpfile} ]; then
                cp ${EVSINaqm}.$DAY/${cpfile} $STATDIR
                sed "s/$model1/${aqmtyp}_${biasc}/g" $STATDIR/${cpfile} > $STATDIR/evs.stats.${aqmtyp}_${biasc}.${RUN}.${VERIF_CASE}.v${DAY}.stat
            else
                echo "WARNING ${COMPONENT} ${STEP} :: Can not find ${EVSINaqm}.$DAY/${cpfile}"
            fi
            DATE=`$NDATE -24 $DATE`
        done
    done
done

for region in CONUS CONUS_East CONUS_West CONUS_South CONUS_Central Appalachia CPlains DeepSouth GreatBasin GreatLakes Mezquital MidAtlantic NorthAtlantic NPlains NRockies PacificNW PacificSW Prairie Southeast Southwest SPlains SRockies; do
    export region
    case ${region} in
        CONUS_East) smregion=conus_e;;
        CONUS_West) smregion=conus_w;
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
        SRockies) smregion=conus;;
        *) smregion="nodefinition";;
    esac

    for inithr in 06 12; do
        export inithr
        export var=OZCON1
        mkdir -p ${COMOUTplots}/${var}
        export lev=A1
        export linetype=SL1L2
        smlev=`echo $lev | tr A-Z a-z`
        smvar=ozone
        
	check_file=evs.${COMPONENT}.fbar_obar.${smvar}_${smlev}.last31days.vhrmean_fday1_init${inithr}z.buk_${smregion}.png
        if [ ! -e ${COMOUTplots}/${var}/${check_file} ]; then
            sh ${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}/py_plotting_awpozcon_fbar_obar_time_series_day1.config
            cat ${LOGDIR}/*out
            mv ${LOGDIR}/*out ${LOGFIN}
        else
            echo "RESTART - plot exists; copying over to plot directory"
            cp ${check_file} ${PLOTDIR}
        fi
        
        if [ -e ${PLOTDIR}/aq/*/evs*png ]; then
            mv ${PLOTDIR}/aq/*/evs*png ${PLOTDIR}/${check_file}
            cp ${PLOTDIR}/${check_file} ${COMOUTplots}/${var}
        elif [ ! -e ${PLOTDIR}/${check_file} ]; then
            echo "NO PLOT FOR",${var},${region}
        fi

        export var=PMTF
        mkdir -p ${COMOUTplots}/${var}
        export lev=L1
        export lev_obs=A1
        export linetype=SL1L2
        smlev=`echo $lev | tr A-Z a-z`
        smvar=pm25
        check_file=evs.${COMPONENT}.fbar_obar.${smvar}_${smlev}.last31days.vhrmean_fday1_init${inithr}z.buk_${smregion}.png ]
        if [ ! -e ${COMOUTplots}/${var}/${check_file} ]; then
            sh ${PARMevs}/metplus_config/${STEP}/${COMPONENT}/${VERIF_CASE}/py_plotting_pm25_fbar_obar_time_series_day1.config
            cat ${LOGDIR}/*out
            mv ${LOGDIR}/*out ${LOGFIN}
        else
            echo "RESTART - plot exists; copying over to plot directory"
            cp ${COMOUTplots}/${var}/${check_file} ${PLOTDIR}
        fi

        if [ -e ${PLOTDIR}/aq/*/evs*png ]; then
            mv ${PLOTDIR}/aq/*/evs*png ${PLOTDIR}/${check_file}
            cp ${PLOTDIR}/${check_file} ${COMOUTplots}/${var}
        elif [ ! -e ${PLOTDIR}/${check_file} ]; then
            echo "NO PLOT FOR",${var},${region}
        fi
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


