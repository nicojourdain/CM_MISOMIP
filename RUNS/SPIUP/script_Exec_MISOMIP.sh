#!/bin/bash
run=SPIUP
RUN_NEMO=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/SPIUP
RUN_ELMER=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/SPIUP/Work

VAL=$1


LINE_NRUN=$(grep -n 'NRUN_MAX=' $RUN_ELMER/scriptIce1rExecute.sh | grep -Eo '^[^:]+')
STRING="NRUN_MAX="$VAL

awk 'NR=='$LINE_NRUN' {$0="'${STRING}'"} 1' $RUN_ELMER/scriptIce1rExecute.sh > test.sh
chmod 755 test.sh 
mv test.sh $RUN_ELMER/scriptIce1rExecute.sh

cd $RUN_NEMO

sbatch ./run_nemo_ISOMIP.sh 0 'DUMMY_FILE'
