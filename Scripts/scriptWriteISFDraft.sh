#!/bin/bash

ISF_GENERIC_FILE=<ISF_DRAFT>
BATHY_FILE=<BATHY_FILE>
ELMER_RUN_PATH=$1
NEMO_RUN_PATH=<NEMO_PATH>
RUN_NUM=$2

ln -sf /home/imerino/From_VTK_TO_NETCDF/build/fromVTKtoElmer fromVTKtoElmer

./fromVTKtoElmer $ELMER_RUN_PATH $ISF_GENERIC_FILE $BATHY_FILE temp.nc

mv temp.nc $NEMO_RUN_PATH/ISF_DRAFT_FROM_ELMER/isf_draft_meter_${RUN_NUM}.nc
