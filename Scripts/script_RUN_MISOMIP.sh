
# Init  NEMO CONDITIONS:
#   RST_FROM_RESTART=0 --> NEMO will be initialized from sal and temp files at y0000
#   RST_FROM_RESTART=1 --> NEMO initial conditions got from RST_FILE
RST_FROM_RESTART=0
RST_FILE='NEMO RESTART FILE'
#RST_FILE=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/input/ISOMIP_restart_00000000.nc

run=<run>
RUN_NEMO=<NEMO_RUN>
RUN_ELMER=<ELMER_RUN>

cd $RUN_ELMER
./scriptInitDomain.sh 1 $RST_FROM_RESTART $RST_FILE

