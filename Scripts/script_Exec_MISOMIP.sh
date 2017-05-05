run=<run>
RUN_NEMO=<NEMO_RUN>
RUN_ELMER=<ELMER_RUN>

cd $RUN_ELMER
# Options: 1 execute NEMO after init Domain, 
#	   0 only initilize Elmer
./scriptInitDomain.sh 1

