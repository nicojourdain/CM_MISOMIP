#!/bin/bash
#SBATCH -C HSW24
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=24
#SBATCH --threads-per-core=1
#SBATCH -J run_ISOMIP_EXP3
#SBATCH -e run_nemo.e%j
#SBATCH -o run_nemo.o%j
#SBATCH --time=01:59:00

date

set -x
ulimit -s unlimited

#=================================================================================
#=================================================================================
# 0- User's choices
#=================================================================================
#=================================================================================

SPINUP=1

CONFIG='ISOMIP'    #- FULL CONFIG NAME (e.g. "trop075" or "trop075_nest025")
                   #  NB: THIS NAME SHOULD NOT START WITH A NUMBER

CONFPAR=$CONFIG    #- IF NO NEST SHOULD BE EQUAL TO $CONFIG
                   #  IF NESTS, SHOULD BE THE ABSOLUTE PARENT CONFIG NAME
                   #  (e.g. CONFPAR="trop075" when CONFIG="trop075_nest025")

CASE='<CASE_NAME>' #- should not be too long (>15 char.) otherwise, NEMO file names are affected

YEAR0=0000         #- initial state of the long experiment (needs four digits)

NDAYS=<DAYS_NEMO>  #- NB: the run is adjusted to give a finite number of months
                   #      => 190 allows  2 x 6-month runs per year
                   #      => 31  allows 12 x 1-month runs per year


WORKDIR=`pwd`

RST_START=$1

RST_FILE=$2

FORCING_EXP_ID=<FORCING_EXP_ID>

PREFIX_ELMER=<PREFIX_ELMER>

ELMER_WORK_PATH=<ELMER_WORK_PATH>
MISOMIP_WORK_PATH=<MISOMIP_WORK_PATH>

STOCKDIR="${SHAREDELMER}/NEMO_MISOMIP"        #- restart, output directory

INPUTDIR="${SHAREDELMER}/NEMO_MISOMIP/input"  #- input directory

#- Netcdf library for small fortran scripts (not for NEMO)
export NC_INC='-I /opt/software/occigen/libraries/netcdf/4.4.0_fortran-4.4.2/hdf5/1.8.17/intel/17.0/openmpi/intel/2.0.1/include'
export NC_LIB='-L /opt/software/occigen/libraries/netcdf/4.4.0_fortran-4.4.2/hdf5/1.8.17/intel/17.0/openmpi/intel/2.0.1/lib -lnetcdf -lnetcdff'

NEMOdir="${HOME}/models/nemo_v3_6_STABLE_r6402/NEMOGCM" #- NEMO model directory
XIOSdir="${HOME}/models/xios-1.0"                       #- XIOS directory

NZOOM=0  #- nb of agrif nests (0 if no agrif nest)

NB_NPROC_XIOS_PER_NODE=2 #- Number of core used per xios on each node (should typically be in the 1-3 range).

#=================================================================================
#=================================================================================
# 1- Initialization
#=================================================================================
#=================================================================================

PWDDIR=`pwd`

export NB_NODES=`echo "${SLURM_NTASKS} / 24" |bc`
export NB_NPROC_IOS=$(( NB_NODES * NB_NPROC_XIOS_PER_NODE ))
export NB_NPROC=$(( SLURM_NTASKS - NB_NPROC_IOS ))

######################
######################
##Temporary test:
######################
######################
#export NB_NPROC_IOS=2
#export NB_NPROC=6

# { unset initiaux 
unset    OMPI_MCA_ess
#
unset    OMPI_MCA_pml
unset    OMPI_MCA_mtl
unset    OMPI_MCA_mtl_mxm_np 
unset    OMPI_MCA_pubsub  
# }

############################################################
##-- create links to executables :

rm -f nemo.exe
if [ $NZOOM -gt 0 ]; then
  ln -s ${NEMOdir}/CONFIG/${CONFIG}_agrif/BLD/bin/nemo.exe
else
  ln -s ${NEMOdir}/CONFIG/${CONFIG}/BLD/bin/nemo.exe
fi

rm -f xios_server.exe
ln -s ${XIOSdir}/bin/xios_server.exe

##############################################
##-- define current year and nb of days

if [ -f prod_nemo.db ]; then
read NRUN YEAR MONTH DAY NITENDM1 NITENDM1ZOOM << EOF
`tail -1 prod_nemo.db`
EOF
else
echo "1 ${YEAR0} 01 01 0" > prod_nemo.db
YEAR=${YEAR0}
MONTH=01
DAY=01
NRUN=1
NITENDM1=0  ## last time step of previous run
## add last time step of previous runs on children domains 
## at the end of the line in prod_nemo.db :
for iZOOM in $(seq 1 ${NZOOM})
do
  sed -e "s/$/ 0/g" prod_nemo.db > tmp
  mv tmp prod_nemo.db
done
fi

# Verify if NEMO is runnning in agreement with the coupled system
NRUN_COUPLED=$( awk '/Coupled_iter:/ {print $2}' ${MISOMIP_WORK_PATH}/COUPLED_Run.db | tail -1 )

if [ ! $NRUN_COUPLED == $NRUN ]:
then
   echo 'NEMO and coupled simulation not in phase ---> STOP'
   exit
fi

#####
# adjust nb of days to finish at the end of the year
ISLEAP=`grep nn_leapy namelist_nemo_GENERIC_${CONFIG} | awk '{print $3}'`
if [ $ISLEAP == 1 ]; then
if [ ! -f calculate_end_date_month ]; then
  ifort -o calculate_end_date_month calculate_end_date_month.f90
fi
echo "$YEAR $MONTH $DAY $NDAYS" > start_date_duration
read YEARf MONTHf DAYf NDAYScorr << EOF
`./calculate_end_date_month`
EOF
if [ $NDAYScorr -ne $NDAYS ]; then
 echo "Adjusting run length to finish at the end of current year"
 NDAYS=$NDAYScorr
 echo "$YEAR $MONTH $DAY $NDAYS" > start_date_duration
read YEARf MONTHf DAYf NDAYScorr << EOF
`./calculate_end_date_month`
EOF
fi
else
if [ ! -f calculate_end_date_noleap_month ]; then
  ifort -o calculate_end_date_noleap_month calculate_end_date_noleap_month.f90
fi
echo "$YEAR $MONTH $DAY $NDAYS" > start_date_duration
read YEARf MONTHf DAYf NDAYScorr << EOF
`./calculate_end_date_noleap_month`
EOF
if [ $NDAYScorr -ne $NDAYS ]; then
 echo "Adjusting run length to finish at the end of current year"
 NDAYS=$NDAYScorr
 echo "$YEAR $MONTH $DAY $NDAYS" > start_date_duration
read YEARf MONTHf DAYf NDAYScorr << EOF
`./calculate_end_date_noleap_month`
EOF
fi
fi
echo " -> Run duration = $NDAYS days"
echo " "

##-- calculate corresponding number of time steps for NEMO:
RN_DT=`grep "rn_rdt " namelist_nemo_GENERIC_${CONFPAR} |grep 'time step for the dynamics' |cut -d '=' -f2 | cut -d '!' -f1 | sed -e "s/ //g"`
NIT000=`echo "$NITENDM1 + 1" | bc`
NITEND=`echo "$NITENDM1 + ${NDAYS} * 86400 / ${RN_DT}" | bc`

echo "****************************************************"
echo "*          NEMO SIMULATION                          "
echo "*   config  $CONFIG                                 "
echo "*   case    $CASE                                   "
echo "*   from    ${DAY}/${MONTH}/${YEAR}                 "
echo "*   to      ${DAYf}/${MONTHf}/${YEARf}              "
echo "*   i.e. step $NIT000 to $NITEND (for mother grid)  "
echo "*                                                   "
echo "*   total number of tasks >>>>> ${SLURM_NTASKS}     "
echo "*   number of xios tasks  >>>>> ${NB_NPROC_IOS}     "
echo "*                                                   "
echo "****************************************************"
echo " "
date
echo " "

#####################################################################
##-- create executable and rebuild namelist to rebuild restart files

rm -f rebuild_nemo.exe
ln -s ${NEMOdir}/TOOLS/REBUILD_NEMO/BLD/bin/rebuild_nemo.exe

###############################################################
##-- edit NEMO's namelist

echo "Editing namelist..."

rm -f namelist_ref namelist_cfg

if [ $NRUN -gt 1 ] || [ $CONFIG == "ISOMIP" -a $RST_START = 1 ]; then
  sed -e "s/RESTNEM/\.true\./g"  namelist_nemo_GENERIC_${CONFPAR} > namelist_ref
  RST=1
else
  sed -e "s/RESTNEM/\.false\./g" namelist_nemo_GENERIC_${CONFPAR} > namelist_ref
  RST=0
fi

##- Specific treatment for TROP075's restart/initial state:
if [ $NRUN -eq 1 ] && [ $CONFIG == "ISOMIP" -a $RST_START = 1 ]; then
  sed -e "s/AAAA/  0 /g" namelist_ref > tmp
  mv -f tmp namelist_ref
else
  sed -e "s/AAAA/  2 /g"  namelist_ref > tmp
  mv -f tmp namelist_ref
fi

sed -e "s/CCCC/${CONFIG}/g ; s/OOOO/${CASE}/g ; s/IIII/${YEAR0}0101/g ; s/NIT000/${NIT000}/g ; s/NITEND/${NITEND}/g" namelist_ref > tmp
mv -f tmp namelist_ref

ln -s namelist_ref namelist_cfg

for iZOOM in $(seq 1 $NZOOM)
do
  echo "Editing ${iZOOM}_namelist..."
  rm -f ${iZOOM}_namelist_ref ${iZOOM}_namelist_cfg
  if [ $NRUN -gt 1 ] || [ $CONFIG == "trop075" ]; then
    sed -e "s/RESTNEM/\.true\./g"  ${iZOOM}_namelist_nemo_GENERIC_${CONFPAR} > ${iZOOM}_namelist_ref
    RST=1
  else
    sed -e "s/RESTNEM/\.false\./g" ${iZOOM}_namelist_nemo_GENERIC_${CONFPAR} > ${iZOOM}_namelist_ref
    RST=0
  fi
  ##- Specific treatment for TROP075's restart/initial state:
  if [ $NRUN -eq 1 ] && [ $CONFIG == "trop075" ]; then
    sed -e "s/AAAA/  0 /g" ${iZOOM}_namelist_ref > tmp
    mv -f tmp ${iZOOM}_namelist_ref
  else
    sed -e "s/AAAA/  2 /g"  ${iZOOM}_namelist_ref > tmp
    mv -f tmp ${iZOOM}_namelist_ref
  fi
  ##- calculate initial and last time step for the child domains :
  ##-- calculate corresponding number of time steps for NEMO:
  RN_DT_ZOOM=`grep "rn_rdt " ${iZOOM}_namelist_nemo_GENERIC_${CONFIG} |cut -d '=' -f2 | cut -d '!' -f1 | sed -e "s/ //g"`
  NIT000_ZOOM=`echo "( ${NITENDM1} * ${RN_DT} / ${RN_DT_ZOOM} ) + 1" | bc`
  NITEND_ZOOM=`echo "( ${NITENDM1} * ${RN_DT} / ${RN_DT_ZOOM} ) + ${NDAYS} * 86400 / ${RN_DT_ZOOM}" | bc`
  ##--
  sed -e "s/CCCC/${CONFIG}/g ; s/OOOO/${CASE}/g ; s/IIII/${YEAR0}0101/g ; s/NIT000/${NIT000_ZOOM}/g ; s/NITEND/${NITEND_ZOOM}/g" ${iZOOM}_namelist_ref > tmp
  mv -f tmp ${iZOOM}_namelist_ref
  ln -s ${iZOOM}_namelist_ref ${iZOOM}_namelist_cfg
done

#rm -f namelist_ice_ref namelist_ice_cfg
#cp -p namelist_ice_nemo_GENERIC_${CONFPAR} namelist_ice_ref
#ln -s namelist_ice_ref namelist_ice_cfg

#############################################################
###-- prepare script that will be used to compress outputs :

STOCKDIR2=`echo $STOCKDIR |sed -e "s/\//\\\\\\\\\//g"`
WORKDIR2=`echo $WORKDIR  |sed -e "s/\//\\\\\\\\\//g"`

sed -e "s/CCCC/${CONFIG}/g ; s/cccc/${CONFPAR}/g ; s/OOOO/${CASE}/g ; s/SSSS/${STOCKDIR2}/g ; s/WWWW/${WORKDIR2}/g ; s/YYYY/${YEAR}/g ; s/NNNN/${NRUN}/g ; s/ZZZZ/${NZOOM}/g ; s/UUUU/${NITEND}/g" compress_nemo_GENERIC.sh > compress_nemo_${NRUN}.sh

chmod +x compress_nemo_${NRUN}.sh

#=======================================================================================
#=======================================================================================
# 2- Manage links to input files
#=======================================================================================
#=======================================================================================

echo " "
date
echo " "
echo " Linking input files from ${INPUTDIR}"

DATE0=`grep nn_date0 namelist_ref | head -1 | awk '{print $3}'`
Y0=`echo $DATE0 | cut -c 1-4`
M0=`echo $DATE0 | cut -c 5-6`

YEARm1=`echo "$YEAR - 1" | bc`
if [ $YEAR -eq $Y0 ]; then
  YEARm1=$Y0  # because no data before
else
  if [ $YEARm1 -lt 1000 ]; then
    YEARm1="0$YEARm1"
  fi
  if [ $YEARm1 -lt 100 ]; then
    YEARm1="0$YEARm1"
  fi
  if [ $YEARm1 -lt 10 ]; then
    YEARm1="0$YEARm1"
  fi
fi
YEARp1=`expr $YEAR + 1`
if [ $YEARp1 -lt 1000 ]; then
  YEARp1="0$YEARp1"
fi
if [ $YEARp1 -lt 100 ]; then
  YEARp1="0$YEARp1"
fi
if [ $YEARp1 -lt 10 ]; then
  YEARp1="0$YEARp1"
fi

##########
##-- import files that are not time dependent if not already there

## CHECK FOR MOVING GEOMETRY :
GEOMOV=`grep ln_iscpl namelist_nemo_GENERIC_${CONFIG} | awk '{print $3}' |sed -e "s/\.//g"`

rm -f bathy_meter.nc
if [ $GEOMOV == 'true' ]; then
  ln -s -v ${INPUTDIR}/bathy_meter.nc bathy_meter.nc
else
  ln -s -v ${INPUTDIR}/bathy_meter.nc bathy_meter.nc
fi 

rm -f isf_draft_meter.nc
if [ $GEOMOV == 'true' ]; then
  ln -s -v ISF_DRAFT_FROM_ELMER/isf_draft_meter_${NRUN}.nc isf_draft_meter.nc
else
  ln -s -v ISF_DRAFT_FROM_ELMER/isf_draft_meter_${NRUN}.nc isf_draft_meter.nc
fi

#rm -f coordinates.nc
#ln -s -v ${INPUTDIR}/coordinates_${CONFPAR}.nc coordinates.nc

rm -f resto.nc
ln -s -v ${INPUTDIR}/resto.nc

for iZOOM in $(seq 1 ${NZOOM})
do

  rm -f ${iZOOM}_bathy_meter.nc
  ln -s -v ${INPUTDIR}/${iZOOM}_bathy_meter_${CONFPAR}.nc ${iZOOM}_bathy_meter.nc

  rm -f ${iZOOM}_isf_draft_meter.nc
  ln -s -v ${INPUTDIR}/${iZOOM}_isf_draft_meter_${CONFPAR}.nc ${iZOOM}_isf_draft_meter.nc

  #rm -f ${iZOOM}_coordinates.nc
  #ln -s -v ${INPUTDIR}/${iZOOM}_coordinates_${CONFPAR}.nc ${iZOOM}_coordinates.nc

done

##########
##-- Initial state or Restart

rm -f restart.nc #restart_ice.nc #restart.obc
rm -f dta_temp_y????m??.nc dta_sal_y????m??.nc dta_temp_y????.nc dta_sal_y????.nc dta_temp.nc dta_sal.nc

if [ $YEARm1 -ge 0 ]; then
  ln -s -v -f ${INPUTDIR}/dta_temp_y0001_${CONFIG}_${FORCING_EXP_ID}.nc dta_temp_y${YEARm1}.nc
  ln -s -v -f ${INPUTDIR}/dta_sal_y0001_${CONFIG}_${FORCING_EXP_ID}.nc  dta_sal_y${YEARm1}.nc
fi

ln -s -v -f ${INPUTDIR}/dta_temp_y0001_${CONFIG}_${FORCING_EXP_ID}.nc   dta_temp_y${YEAR}.nc
ln -s -v -f ${INPUTDIR}/dta_sal_y0001_${CONFIG}_${FORCING_EXP_ID}.nc    dta_sal_y${YEAR}.nc
ln -s -v -f ${INPUTDIR}/dta_temp_y0000_${CONFIG}_${FORCING_EXP_ID}.nc   dta_temp_y0000.nc
ln -s -v -f ${INPUTDIR}/dta_sal_y0000_${CONFIG}_${FORCING_EXP_ID}.nc    dta_sal_y0000.nc
ln -s -v -f ${INPUTDIR}/dta_temp_y0001_${CONFIG}_${FORCING_EXP_ID}.nc dta_temp_y${YEARp1}.nc
ln -s -v -f ${INPUTDIR}/dta_sal_y0001_${CONFIG}_${FORCING_EXP_ID}.nc  dta_sal_y${YEARp1}.nc



#IF we are in spinup cold conditions all along the simulation (EXP4-->cold conditions)
#if [ $FORCING_CONDS == 'COLD' ];
#then
#    ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP4.nc   dta_temp_y${YEAR}.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP4.nc    dta_sal_y${YEAR}.nc
#    ln -s -v ${INPUTDIR}/dta_temp_y0000_${CONFIG}_EXP4.nc   dta_temp_y0000.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0000_${CONFIG}_EXP4.nc    dta_sal_y0000.nc
#    ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP4.nc dta_temp_y${YEARp1}.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP4.nc  dta_sal_y${YEARp1}.nc
#    if [ $YEARm1 -ge 0 ]; then
#       ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP4.nc dta_temp_y${YEARm1}.nc
#       ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP4.nc  dta_sal_y${YEARm1}.nc
#    fi

#elif [ $FORCING_CONDS == 'WARM' ];
#then
#    ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP3.nc   dta_temp_y${YEAR}.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP3.nc    dta_sal_y${YEAR}.nc
#    ln -s -v ${INPUTDIR}/dta_temp_y0000_${CONFIG}_EXP3.nc   dta_temp_y0000.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0000_${CONFIG}_EXP3.nc    dta_sal_y0000.nc
#    ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP3.nc dta_temp_y${YEARp1}.nc
#    ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP3.nc  dta_sal_y${YEARp1}.nc
#    if [ $YEARm1 -ge 0 ]; then
#       ln -s -v ${INPUTDIR}/dta_temp_y0001_${CONFIG}_EXP3.nc dta_temp_y${YEARm1}.nc
#       ln -s -v ${INPUTDIR}/dta_sal_y0001_${CONFIG}_EXP3.nc  dta_sal_y${YEARm1}.nc
#    fi
#fi


RSTN=`grep "from a restart file" namelist_ref | awk '{print $3}' | sed -e "s/\.//g"`
NIT_RST=${NITENDM1}
if [ $RSTN == "true" ]; then
  if [ $NIT_RST -eq 0 ]; then
    ln -s -v $RST_FILE restart.nc
    #ln -s -v ${INPUTDIR}/${CONFPAR}_restart_ice_00000000.nc restart_ice.nc
  else
    #if [ ! -f restart_${NIT_RST}.nc ] || [ ! -f restart_${NIT_RST}.obc ]; then
    if [ ! -f restart_${NIT_RST}.nc ]; then
      echo "Copy ocean restart file from ${STOCKDIR}/restart/nemo_${CONFIG}-${CASE}"
      cp -p ${STOCKDIR}/restart/nemo_${CONFIG}_${CASE}/restart_${NIT_RST}.nc .
    fi
    ln -s -v restart_${NIT_RST}.nc   restart.nc
    #if [ ! -f restart_ice_${NIT_RST}.nc ]; then
    #  echo "Copy ice restart file from ${STOCKDIR}/restart/nemo_${CONFIG}-${CASE}"
    #  cp -p ${STOCKDIR}/restart/nemo_${CONFIG}_${CASE}/restart_ice_${NIT_RST}.nc .
    #fi
    #ln -s -v restart_ice_${NIT_RST}.nc   restart_ice.nc
    ##ln -s -v restart_${NIT_RST}.obc  restart.obc
  fi
else
  echo "Not in restart mode -> read initial T,S state"
fi

for iZOOM in $(seq 1 ${NZOOM})
do

  rm -f ${iZOOM}_restart.nc #${iZOOM}_restart_ice.nc
  rm -f ${iZOOM}_dta_temp_y????m??.nc ${iZOOM}_dta_sal_y????m??.nc ${iZOOM}_dta_temp_y????.nc ${iZOOM}_dta_sal_y????.nc ${iZOOM}_dta_temp.nc ${iZOOM}_dta_sal.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_temp_y${YEAR}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_temp_y${YEAR}.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_sal_y${YEAR}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_sal_y${YEAR}.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_temp_y${YEARm1}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_temp_y${YEARm1}.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_sal_y${YEARm1}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_sal_y${YEARm1}.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_temp_y${YEARp1}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_temp_y${YEARp1}.nc
  ln -s -v ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_sal_y${YEARp1}_${CONFIG}_EXP3.nc  ${iZOOM}_dta_sal_y${YEARp1}.nc
  RSTN=`grep "from a restart file" namelist_ref | awk '{print $3}' | sed -e "s/\.//g"`
  NIT_RST=${NITENDM1}
  if [ $RSTN == "true" ]; then
    if [ $NIT_RST -eq 0 ]; then
      ln -s -v ${INPUTDIR}/${iZOOM}_${CONFPAR}_restart_00000000.nc ${iZOOM}_restart.nc
      #ln -s -v ${INPUTDIR}/${iZOOM}_${CONFPAR}_restart_ice_00000000.nc ${iZOOM}_restart_ice.nc
    else
      if [ ! -f ${iZOOM}_restart_${NIT_RST}.nc ]; then
        echo "Copy zoom ocean restart file from ${STOCKDIR}/restart/nemo_${CONFIG}-${CASE}"
        cp -p ${STOCKDIR}/restart/nemo_${CONFIG}_${CASE}/${iZOOM}_restart_${NIT_RST}.nc .
      fi
      ln -s -v ${iZOOM}_restart_${NIT_RST}.nc   ${iZOOM}_restart.nc
      #if [ ! -f ${iZOOM}_restart_ice_${NIT_RST}.nc ]; then
      #  echo "Copy zoom ice restart file from ${STOCKDIR}/restart/nemo_${CONFIG}-${CASE}"
      #  cp -p ${STOCKDIR}/restart/nemo_${CONFIG}_${CASE}/${iZOOM}_restart_ice_${NIT_RST}.nc .
      #fi
      #ln -s -v ${iZOOM}_restart_ice_${NIT_RST}.nc   ${iZOOM}_restart_ice.nc
    fi
  else
    echo "Not in restart mode -> import initial T,S state for the zoom"
    if [ ! -f ${iZOOM}_dta_temp_${CONFIG}_y${Y0}m${M0}.nc ] || [ ! -f ${iZOOM}_dta_sal_${CONFIG}_y${Y0}m${M0}.nc ]; then
      echo "Copy zoom initial state from ${INPUTDIR}"
      cp -p ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_temp_${CONFPAR}_y${Y0}m${M0}.nc
      cp -p ${INPUTDIR}/DTA_EXP3/${iZOOM}_dta_sal_${CONFPAR}_y${Y0}m${M0}.nc
    fi
  fi

done

echo " "
echo "Import (links+copy) of input files completed."
echo " "
echo "Launching the long nemo simulation"
echo " "

#=======================================================================================
#=======================================================================================
# 3- Run script
#=======================================================================================
#=======================================================================================

rm -f app.conf
echo "0-$(( NB_NPROC_IOS - 1 )) xios_server.exe"          >  app.conf
echo "${NB_NPROC_IOS}-$(( SLURM_NTASKS - 1 )) nemo.exe "  >> app.conf

date
echo " "

srun --mpi=pmi2  -m cyclic \
    --cpu_bind=map_cpu:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23\
    --multi-prog  ./app.conf

#srun --mpi=pmi2 --multi-prog  ./app.conf



echo " "
date
echo " "

##-- export and compress output files:

if [ ! -d OUTPUT_${NRUN} ]; then
  mkdir OUTPUT_${NRUN}
fi

mv -f ${CONFIG}-${CASE}_[1-5][d-m]_*nc OUTPUT_${NRUN}/.
mv -f namelist_ref                     OUTPUT_${NRUN}/namelist.${NRUN}
#mv -f namelist_ice_ref                 OUTPUT_${NRUN}/namelist_ice.${NRUN}
mv -f ocean.output                     OUTPUT_${NRUN}/ocean.output.${NRUN}
#rm -f namelist_ice_cfg namelist_cfg

for iZOOM in $(seq 1 ${NZOOM})
do
  mv -f ${iZOOM}_${CONFPAR}-${CASE}_[1-5][d-m]_*nc  OUTPUT_${NRUN}/.
  mv -f ${iZOOM}_namelist_ref                       OUTPUT_${NRUN}/${iZOOM}_namelist.${NRUN}
  #mv -f ${iZOOM}_namelist_ice_ref                   OUTPUT_${NRUN}/${iZOOM}_namelist_ice.${NRUN}
  mv -f ${iZOOM}_ocean.output                       OUTPUT_${NRUN}/${iZOOM}_ocean.output.${NRUN}
  #rm -f ${iZOOM}_namelist_ice_cfg ${iZOOM}_namelist_cfg
done

## used to know how many multiple output files are created (in xios mode "multiple_file")
echo "xxx $NB_NPROC_IOS xios_server.exe xxx" > OUTPUT_${NRUN}/app.copy

##########################################################
##-- rebuild mesh_mask file :

./rebuild_mesh_mask.sh

if [ -f mesh_mask.nc ]; then
  mv mesh_mask.nc OUTPUT_${NRUN}/mesh_mask_${YEAR}${MONTH}${DAY}.nc
else
  echo ' '
  echo '~!@#$%^&* mesh_mask.nc has not been created >>>>>>>> stop !!!'
  echo ' '
  exit
fi

##########################################################
##-- prepare next run if every little thing went all right

NTEST_O=`ls -1 OUTPUT_${NRUN}/${CONFIG}-${CASE}_[1-5][d-m]_*nc |wc -l`
NTEST_R=`ls -1 ${CONFIG}-${CASE}_*_restart_*.nc |wc -l`

if [ ${NTEST_O} -gt 0 ] && [ ${NTEST_R} -gt 0 ]; then

  jobidComp=$(sbatch --parsable ./compress_nemo_${NRUN}.sh)

  ##-- write last restart time step of mother grid in prod_nemo.db:
  LAST_RESTART_NIT=`ls -lrt ${CONFIG}-${CASE}_*_restart_*.nc |tail -1 | sed -e "s/${CONFIG}-${CASE}//g" | cut -d '_' -f2`
  echo " "
  echo "Last restart created at ocean time step ${LAST_RESTART_NIT}"
  echo "  ---> writting this date in prod_nemo.db"
  echo " "
  echo "$LAST_RESTART_NIT" > restart_nit.txt
  ##-- add last restart time step on chidren grids (at the end of last line in prod_nemo.db):
  for iZOOM in $(seq 1 ${NZOOM})
  do
    LAST_RESTART_NIT_ZOOM=`ls -lrt ${iZOOM}_${CONFIG}-${CASE}_*_restart_*.nc |tail -1 | sed -e "s/${iZOOM}_${CONFIG}-${CASE}//g" | cut -d '_' -f2`
    sed -e "`wc -l prod_nemo.db|cut -d ' ' -f1`s/$/ ${LAST_RESTART_NIT_ZOOM}/g" prod_nemo.db > tmp
    mv tmp prod_nemo.db
    echo " "
    echo "Last restart created for zoom nb $iZOOM at ocean time step ${LAST_RESTART_NIT_ZOOM}"
    echo "  ---> writting this date in prod_nemo.db"
    echo " "
    echo "$LAST_RESTART_NIT_ZOOM" > ${iZOOM}_restart_nit.txt
  done

  echo " "
  date
  echo " "

  ## rebuild restart file for mother grid :
  FILEBASE=`ls -1 ${CONFIG}-${CASE}_[0-9]???????_restart_0000.nc | sed -e "s/_0000.nc//g"`
  NDOMAIN=`ls -1 ${CONFIG}-${CASE}_[0-9]???????_restart_[0-9]???.nc | wc -l`
  cat > nam_rebuild << EOF
  &nam_rebuild
  filebase='${FILEBASE}'
  ndomain=${NDOMAIN}
  /
EOF
  cat nam_rebuild
  echo " "
  echo "./rebuild_nemo.exe"
  ./rebuild_nemo.exe
  if [ -f ${FILEBASE}.nc ]; then
    LAST_RESTART_NIT_ZOOM=`echo ${FILEBASE} | sed -e "s/${CONFIG}-${CASE}_//g" | cut -d '_' -f1`
    mv  ${FILEBASE}.nc restart_${LAST_RESTART_NIT_ZOOM}.nc
    rm -f ${FILEBASE}_[0-9]???.nc
  else
    echo "~!@#%^& PROBLEM WITH REBUILD OF ${FILEBASE}.nc >>>>>>>>>>>>>>> stop !!!"
    exit
  fi

  echo " "
  date
  echo " "

#  ## rebuild restart_ice file for mother grid :
#  FILEBASE=`ls -1 ${CONFIG}-${CASE}_[0-9]???????_restart_ice_0000.nc | sed -e "s/_0000.nc//g"`
#  NDOMAIN=`ls -1 ${CONFIG}-${CASE}_[0-9]???????_restart_ice_[0-9]???.nc | wc -l`
#  cat > nam_rebuild << EOF
#  &nam_rebuild
#  filebase='${FILEBASE}'
#  ndomain=${NDOMAIN}
#  /
#EOF
#  cat nam_rebuild
#  echo " "
#  echo "./rebuild_nemo.exe"
#  ./rebuild_nemo.exe
#  if [ -f ${FILEBASE}.nc ]; then
#    LAST_RESTART_NIT_ZOOM=`echo ${FILEBASE} | sed -e "s/${CONFIG}-${CASE}_//g" | cut -d '_' -f1`
#    mv  ${FILEBASE}.nc restart_ice_${LAST_RESTART_NIT_ZOOM}.nc
#    rm -f ${FILEBASE}_[0-9]???.nc
#  else
#    echo "~!@#%^& PROBLEM WITH REBUILD OF ${FILEBASE}.nc >>>>>>>>>>>>>>> stop !!!"
#    exit
#  fi

  echo " "
  date
  echo " "

  # prepare initial state for following iteration:
  NRUNm1=$NRUN 
  NRUNm2=`expr $NRUN - 1`
  NRUN=`expr $NRUN + 1`
  TMPTMP="${LAST_RESTART_NIT}"
  for iZOOM in $(seq 1 ${NZOOM})
  do
    LAST_RESTART_NIT_ZOOM=`cat ${iZOOM}_restart_nit.txt`
    TMPTMP="${TMPTMP} ${LAST_RESTART_NIT_ZOOM}"
  done
  echo "${NRUN} ${YEARf} ${MONTHf} ${DAYf} ${TMPTMP}" >> prod_nemo.db    ## new line

else

  echo ' '
  echo '!@#$%^&* BIG PROBLEM : no output or no restart files created for NEMO !! >>>>>>> STOP'
  exit

fi

##########################################################
##-- launch next year of the experiment

Melt_Rate_Path=${STOCKDIR}/output/nemo_${CONFIG}_${CASE}/${YEAR}
ln -sf $WORKDIR/ISF_DRAFT_FROM_ELMER/isf_draft_meter_$(( NRUN - 1)).nc $ELMER_WORK_PATH/isf_draft_meter.nc

$MISOMIP_WORK_PATH/write_coupling_run_info.sh 0 $(( NRUN -1 )) 0 0 'dummyfile' $WORKDIR/OUTPUT_$NRUNm1/ocean.output.$NRUNm1

cd $ELMER_WORK_PATH
if [ $PREFIX_ELMER == 'Ice1r' ]; then
   ./scriptIce1rExecute.sh $(( NRUN - 1)) $jobidComp $Melt_Rate_Path
elif [ $PREFIX_ELMER == 'Ice1a' ]; then
   ./scriptIce1aExecute.sh $(( NRUN - 1)) $jobidComp $Melt_Rate_Path
else
  echo 'ERROR in PREFIX_ELMER, PREFIX_ELMER does not match any of the considered cases case >>>>>>> STOP'
  exit
fi
echo " "
date
