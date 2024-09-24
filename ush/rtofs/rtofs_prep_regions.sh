#!/bin/bash
###############################################################################
# Name of Script: rtofs_regions.sh
# Purpose of Script: To create RTOFS subregions with ice mask for calculating
#    performance metrics.
# Author: L. Gwen Chen (lichuan.chen@noaa.gov)
#         Mallory Row (mallory.row@noaa.gov)
###############################################################################

set -x

# create ice mask: ice grids are defined as grids with ice coverage >= 0.15
#     from RTOFS nowcast (i.e., f000 forecast)
# use non-ice grids to calculate stats
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/rtofs_glo_2ds_f000_ice.$RUN.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/rtofs_glo_2ds_f000_ice.$RUN.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/rtofs_glo_2ds_f000_ice.$RUN.nc \
        $DATA/rtofs.$INITDATE/$RUN/ice_mask.nc \
        -type data -mask_field 'name="ice_coverage"; level="(0,*,*)";' -thresh lt0.15 -name ice_mask
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/ice_mask.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

# create subregions using ice mask
#   Global
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.global.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.global.nc \
        -type lat -thresh 'ge-80 && le90' -intersection -name GLB
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.global.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.global.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   North Atlantic Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc \
        -type lat -thresh 'ge0 && le60' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.north_atlantic.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_atlantic.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.north_atlantic.nc \
        -type lon -thresh 'ge-98 && le10' -intersection -name NATL
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.north_atlantic.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.north_atlantic.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   South Atlantic Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc \
        -type lat -thresh 'ge-80 && le0' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.south_atlantic.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_atlantic.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.south_atlantic.nc \
        -type lon -thresh 'ge-70 && le20' -intersection -name SATL
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.south_atlantic.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.south_atlantic.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   Equatorial Atlantic Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc ]; then
     if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
         gen_vx_mask \
         $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
         $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
         $DATA/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc \
         -type lat -thresh 'ge-30 && le30' -intersection
         export err=$?; err_chk
         if [ $SENDCOM = "YES" ]; then
		 if [ -s $DATA/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc ]; then
             		cp -v $DATA/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		 fi
         fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.equatorial_atlantic.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_atlantic.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_atlantic.nc \
        -type lon -thresh 'ge-80 && le30' -intersection -name EQATL
        export err=$?; err_chk
         if [ $SENDCOM = "YES" ]; then
		 if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_atlantic.nc ]; then
             		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_atlantic.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		 fi
         fi
    fi
fi

#   North Pacific Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/north_pacific.lat.nc \
        -type lat -thresh 'ge0 && le70' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/north_pacific.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/north_pacific.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/northeast_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/northeast_pacific.nc \
        -type lon -thresh 'ge-180 && le-84' -intersection -name NEPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/northeast_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/northeast_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/northwest_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/north_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/northwest_pacific.nc \
        -type lon -thresh 'ge101 && le180' -intersection -name NWPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/northwest_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/northwest_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.north_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/northeast_pacific.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/northeast_pacific.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/northwest_pacific.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.north_pacific.nc \
        -type data -mask_field 'name="NWPAC"; level="(*,*)";' -thresh eq1 -union -name NPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.north_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.north_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   South Pacific Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/south_pacific.lat.nc \
        -type lat -thresh 'ge-80 && le0' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/south_pacific.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/south_pacific.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/southeast_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/southeast_pacific.nc \
        -type lon -thresh 'ge-180 && le-70' -intersection -name SEPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/southeast_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/southeast_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/southwest_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/south_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/southwest_pacific.nc \
        -type lon -thresh 'ge115 && le180' -intersection -name SWPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/southwest_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/southwest_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
   fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.south_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/southeast_pacific.nc ] && [ -s $EVSINprep/rtofs.$INITDATE/$RUN/southwest_pacific.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/southeast_pacific.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/southwest_pacific.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.south_pacific.nc \
        -type data -mask_field 'name="SWPAC"; level="(*,*)";' -thresh eq1 -union -name SPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.south_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.south_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
   fi
fi

#   Equatorial Pacific Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc \
        -type lat -thresh 'ge-30 && le30' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/centraleast_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/centraleast_pacific.nc \
        -type lon -thresh 'ge-180 && le-80' -intersection -name CEPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/centraleast_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/centraleast_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/centralwest_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/equatorial_pacific.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/centralwest_pacific.nc \
        -type lon -thresh 'ge115 && le180' -intersection -name CWPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/centralwest_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/centralwest_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.equatorial_pacific.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/centraleast_pacific.nc ] && [ -s $EVSINprep/rtofs.$INITDATE/$RUN/centralwest_pacific.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/centraleast_pacific.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/centralwest_pacific.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_pacific.nc \
        -type data -mask_field 'name="CWPAC"; level="(*,*)";' -thresh eq1 -union -name EQPAC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_pacific.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.equatorial_pacific.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   Indian Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/indian.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/indian.lat.nc \
        -type lat -thresh 'ge-75 && le30' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/indian.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/indian.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.indian.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/indian.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/indian.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/indian.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.indian.nc \
        -type lon -thresh 'ge20 && le115' -intersection -name IND
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.indian.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.indian.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   Southern Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.southern.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.southern.nc \
        -type lat -thresh 'ge-80 && le-30' -intersection -name SOC
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.southern.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.southern.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   Arctic Ocean
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.arctic.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.arctic.nc \
        -type lat -thresh 'ge50 && le90' -intersection -name Arctic
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.arctic.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.arctic.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

#   Mediterranean Sea
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mediterranean.lat.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/ice_mask.nc \
        $DATA/rtofs.$INITDATE/$RUN/mediterranean.lat.nc \
        -type lat -thresh 'ge29 && le48' -intersection
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mediterranean.lat.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mediterranean.lat.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi
if [ ! -s $COMOUTprep/rtofs.$INITDATE/$RUN/mask.mediterranean.nc ]; then
    if [ -s $EVSINprep/rtofs.$INITDATE/$RUN/mediterranean.lat.nc ]; then
        gen_vx_mask \
        $EVSINprep/rtofs.$INITDATE/$RUN/mediterranean.lat.nc \
        $EVSINprep/rtofs.$INITDATE/$RUN/mediterranean.lat.nc \
        $DATA/rtofs.$INITDATE/$RUN/mask.mediterranean.nc \
        -type lon -thresh 'ge-2 && le45' -intersection -name MEDIT
        export err=$?; err_chk
        if [ $SENDCOM = "YES" ]; then
		if [ -s $DATA/rtofs.$INITDATE/$RUN/mask.mediterranean.nc ]; then
            		cp -v $DATA/rtofs.$INITDATE/$RUN/mask.mediterranean.nc $COMOUTprep/rtofs.$INITDATE/$RUN
		fi
        fi
    fi
fi

################################ END OF SCRIPT ################################
