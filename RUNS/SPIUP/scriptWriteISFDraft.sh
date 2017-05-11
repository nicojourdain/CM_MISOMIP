#!/bin/bash

ISF_GENERIC_FILE=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/input/isf_draft_meter.nc
BATHY_FILE=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/input/bathy_meter.nc
ELMER_RUN_PATH=$1
NEMO_RUN_PATH=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/SPIUP
RUN_NUM=$2

ln -sf /home/imerino/From_VTK_TO_NETCDF/build/fromVTKtoElmer fromVTKtoElmer

./fromVTKtoElmer $ELMER_RUN_PATH $ISF_GENERIC_FILE $BATHY_FILE temp.nc

mv temp.nc $NEMO_RUN_PATH/ISF_DRAFT_FROM_ELMER/isf_draft_meter_${RUN_NUM}.nc
