run=<run>
RUN_NEMO=<NEMO_RUN>
RUN_ELMER=<ELMER_RUN>

RST_FILE=<RESTART_FILE>
#RST_FILE=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/input/ISOMIP_restart_00000000.nc

cd $RUN_ELMER
# Options: 1 execute NEMO after init Domain, 
#	   0 only initilize Elmer
./scriptInitDomain.sh 1 1 $RST_FILE

