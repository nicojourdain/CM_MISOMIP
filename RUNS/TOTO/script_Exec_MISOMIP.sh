run=TOTO
RUN_NEMO=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/TOTO
RUN_ELMER=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/TOTO/Work

cd $RUN_ELMER
# Options: 1 execute NEMO after init Domain, 
#	   0 only initilize Elmer
./scriptInitDomain.sh 1

