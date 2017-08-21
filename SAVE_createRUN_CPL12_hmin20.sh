#!/bin/bash

export LANG=C

###################################################
## User's choices :
###################################################

NUM_PARTITIONS_ELMER=24
NUM_NODES_ELMER=1

NRUN_MAX=100  # maximum number of consecutive Elmer/Ice runs

ELMER_MESH_NAME=MISMIP_REGULAR

TIME_STEP_ELMER=0.0833333333         # ELMER time step (in yr)
INTERVALS_ELMER=12                   # duration of ELMER run (in nb time steps)
FREQ_OUTPUT_ELMER=${INTERVALS_ELMER} # frequency for ELMER outputs
                                     #   NB1: should be ${INTERVALS_ELMER}
                                     #        or ${INTERVALS_ELMER} times an integer
                                     #   NB2: there is also another output at ELMER's initial step
# Number of days in NEMO (will be rounded to an exact number of months later):
NEMO_DAYS_RUN=`echo "31 * ${TIME_STEP_ELMER} * ${INTERVALS_ELMER} * 12" | bc -l | awk '{print int($1+0.5)}'`

## Elmer/Ice restart used as initial state for the coupled simultion
#  NB: restart file is expected to be in ${PATH_RESTART}/${CASE_RESTART}/Results/${RUN_RESTART} 
#                           with Mesh in ${PATH_RESTART}/${CASE_RESTART}/Mesh/${RUN_RESTART} 
PATH_RESTART=${STOREDIR}/output_MISMIP+
CASE_RESTART=Test500m_Schoof_SSAStar
RUN_RESTART=Run0

FORCING_EXP_ID='EXP3'  ## ='EXP3' for ocean relaxation towards warm conditions 
                       ## ='EXP4' for ocean relaxation towards cold conditions

PREFIX_ELMER='Ice1r'   ## ='Ice1r' for retreat and warm ocean forcing (FORCING_EXP_ID=EXP3)
                       ## ='Ice1a' for readvance and cold ocean forcing (FORCING_EXP_ID=EXP4)

# NEMO restart file (only used if you do not start with the ocean at rest, e.g. to restart MISOMIP)
RST_FILE='/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/IceOcean1r_TEST/restart_15846192.nc'

WORKDIR_NEMO=/scratch/shared/egige60/NEMO_MISOMIP
WORKDIR_ELMER=/scratch/shared/egige60/ELMER_MISOMIP

#nj CASE_RESTART_PATH=/scratch/cnt0021/gge6066/imerino/MISMIP+/$CASE_RESTART/Results/$RUN_RESTART
BATHY_FILE=${WORKDIR_NEMO}/input/bathy_meter.nc
ISF_DRAFT_GENERIC=${WORKDIR_NEMO}/input/isf_draft_meter.nc

From_VTK_TO_NETCDF_PATH=${HOME}/util/From_VTK_to_NetCDF/build/fromVTKtoElmer

###################################################
## End of User's choices
###################################################

echo "Creating Run $1"
echo "  > time slots of ${NEMO_DAYS_RUN} days (rounded to full nb of months)"
echo "  > experiment is ${FORCING_EXP_ID} / ${PREFIX_ELMER}"

#Create folders
HOMEDIR_MISOMIP=$PWD/RUNS/$1
mkdir -p $HOMEDIR_MISOMIP
mkdir -p $WORKDIR_ELMER/$1
mkdir -p $WORKDIR_NEMO/run/$1
mkdir -p $WORKDIR_ELMER/$1/Executables
mkdir -p $WORKDIR_ELMER/$1/Results
mkdir -p $WORKDIR_ELMER/$1/Work

ELMER_WORK_PATH=$WORKDIR_ELMER/$1/Work

#Files in HOMEDIR

ln -sf $From_VTK_TO_NETCDF_PATH $HOMEDIR_MISOMIP/fromVTKtoElmer

cat Makefile_G | sed -e "s#<ExecutablePath>#$WORKDIR_ELMER/$1/Executables/#g" > $ELMER_WORK_PATH/Makefile

cat Scripts/scriptWriteISFDraft.sh | sed -e "s#<ISF_DRAFT>#$ISF_DRAFT_GENERIC#g" \
                 -e "s#<BATHY_FILE>#$BATHY_FILE#g" \
                 -e "s#<VTK_EXE>#${From_VTK_TO_NETCDF_PATH}#g" \
                 -e "s#<NEMO_PATH>#$WORKDIR_NEMO/run/$1#g" > $HOMEDIR_MISOMIP/scriptWriteISFDraft.sh
chmod a+rx $HOMEDIR_MISOMIP/scriptWriteISFDraft.sh


cat Scripts/scriptIce1rExecute.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<NRUN_MAX>#$NRUN_MAX#g" \
                 -e "s#<HOMEDIR_MISOMIP>#$HOMEDIR_MISOMIP#g" \
                 -e "s#<OUTPUT_FREQ_ELMER>#$FREQ_OUTPUT_ELMER#g" \
                 -e "s#<INTERVALS_ELMER>#$INTERVALS_ELMER#g" \
                 -e "s#<TIME_STEP_ELMER>#$TIME_STEP_ELMER#g" \
                 -e "s#<numParts>#$NUM_PARTITIONS_ELMER#g" \
                 -e "s#<numNodes>#$NUM_NODES_ELMER#g" \
                 -e "s#<WORKDIR_ELMER>#$WORKDIR_ELMER#g" \
                 -e "s#<Executables>#$WORKDIR_ELMER/$1/Executables/#g" \
                 -e "s#<MeshNamePath>#$WORKDIR_ELMER/$1#g" > $ELMER_WORK_PATH/scriptIce1rExecute.sh
chmod a+rx $ELMER_WORK_PATH/scriptIce1rExecute.sh

cat Scripts/scriptIce1aExecute.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<NRUN_MAX>#$NRUN_MAX#g" \
                 -e "s#<HOMEDIR_MISOMIP>#$HOMEDIR_MISOMIP#g" \
                 -e "s#<OUTPUT_FREQ_ELMER>#$FREQ_OUTPUT_ELMER#g" \
                 -e "s#<INTERVALS_ELMER>#$INTERVALS_ELMER#g" \
                 -e "s#<TIME_STEP_ELMER>#$TIME_STEP_ELMER#g" \
                 -e "s#<numParts>#$NUM_PARTITIONS_ELMER#g" \
                 -e "s#<numNodes>#$NUM_NODES_ELMER#g" \
                 -e "s#<WORKDIR_ELMER>#$WORKDIR_ELMER#g" \
                 -e "s#<Executables>#$WORKDIR_ELMER/$1/Executables/#g" \
                 -e "s#<MeshNamePath>#$WORKDIR_ELMER/$1#g" > $ELMER_WORK_PATH/scriptIce1aExecute.sh
chmod a+rx $ELMER_WORK_PATH/scriptIce1aExecute.sh

cat Scripts/scriptInitDomain.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<caseTest>#$CASE_RESTART#g" \
                 -e "s#<path_restart>#$PATH_RESTART#g" \
                 -e "s#<HOMEDIR_MISOMIP>#$HOMEDIR_MISOMIP#g" \
                 -e "s#<RunRestart>#$RUN_RESTART#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<numParts>#$NUM_PARTITIONS_ELMER#g" \
                 -e "s#<numNodes>#$NUM_NODES_ELMER#g" \
                 -e "s#<WORKDIR_ELMER>#$WORKDIR_ELMER#g" \
                 -e "s#<Executables>#$WORKDIR_ELMER/$1/Executables/#g" \
                 -e "s#<MeshNamePath>#$WORKDIR_ELMER/$1#g" > $ELMER_WORK_PATH/scriptInitDomain.sh
chmod a+rx $ELMER_WORK_PATH/scriptInitDomain.sh

cat Scripts/write_coupling_run_info.sh | sed -e "s#<HOMEDIR_MISOMIP>#$HOMEDIR_MISOMIP#g" > $HOMEDIR_MISOMIP/write_coupling_run_info.sh
chmod a+rx $HOMEDIR_MISOMIP/write_coupling_run_info.sh

cat Scripts/script_Exec_MISOMIP.sh | sed -e "s#<run>#$1#g" \
		 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<ELMER_RUN>#$ELMER_WORK_PATH#g" > $HOMEDIR_MISOMIP/script_Exec_MISOMIP.sh
chmod a+rx $HOMEDIR_MISOMIP/script_Exec_MISOMIP.sh

cat Scripts/script_RUN_MISOMIP.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<ELMER_RUN>#$ELMER_WORK_PATH#g" > $HOMEDIR_MISOMIP/script_RUN_MISOMIP.sh
chmod a+rx $HOMEDIR_MISOMIP/script_RUN_MISOMIP.sh

cat Scripts/script_SpinUp_MISOMIP.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<ELMER_RUN>#$ELMER_WORK_PATH#g" > $HOMEDIR_MISOMIP/script_SpinUp_MISOMIP.sh
chmod a+rx $HOMEDIR_MISOMIP/script_SpinUp_MISOMIP.sh

cat Scripts/script_Start_From_Restart.sh | sed -e "s#<run>#$1#g" \
                 -e "s#<NEMO_RUN>#$WORKDIR_NEMO/run/$1#g" \
                 -e "s#<RESTART_FILE>#$RST_FILE#g" \
                 -e "s#<ELMER_RUN>#$ELMER_WORK_PATH#g" > $HOMEDIR_MISOMIP/script_Start_From_Restart.sh
chmod a+rx $HOMEDIR_MISOMIP/script_Start_From_Restart.sh

cp Scripts/read_write_Elmer_run_info.sh $HOMEDIR_MISOMIP/read_write_Elmer_run_info.sh
chmod a+rx $HOMEDIR_MISOMIP/read_write_Elmer_run_info.sh

#Set files in Workdir NEMO
cp $WORKDIR_NEMO/FILES/* $WORKDIR_NEMO/run/$1

cat Scripts/run_nemo_ISOMIP.sh | sed -e "s#<CASE_NAME>#$1#g"  \
                 -e "s#<DAYS_NEMO>#$NEMO_DAYS_RUN#g" \
                 -e "s#<FORCING_EXP_ID>#$FORCING_EXP_ID#g" \
                 -e "s#<PREFIX_ELMER>#$PREFIX_ELMER#g" \
                 -e "s#<MISOMIP_WORK_PATH>#$HOMEDIR_MISOMIP#g" \
                -e "s#<ELMER_WORK_PATH>#$ELMER_WORK_PATH#g"> temp.sh
mv temp.sh $WORKDIR_NEMO/run/$1/run_nemo_ISOMIP.sh
chmod a+rx $WORKDIR_NEMO/run/$1/run_nemo_ISOMIP.sh

cd $WORKDIR_NEMO/run/$1
mkdir -p ISF_DRAFT_FROM_ELMER

ln -sf $WORKDIR_NEMO/run/$1 $HOMEDIR_MISOMIP/WORK_NEMO
ln -sf $ELMER_WORK_PATH $HOMEDIR_MISOMIP/WORK_ELMER

#SetFiles

#COMPILING ELMER SOLVERS


