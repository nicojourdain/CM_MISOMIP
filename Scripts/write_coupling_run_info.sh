#!/bin/bash
HOMEDIR_MISOMIP=<HOMEDIR_MISOMIP>

BEGIN_COUPLED=$1
END_NEMO=$2
END_ELMER=$3
END_COUPLED=$4

echo 'write infor' $BEGIN_COUPLED $END_NEMO $END_ELMER $END_COUPLED

if [ ! -f $HOMEDIR_MISOMIP/COUPLED_Run.db ];
then
   echo 'NumRun  ' 'Elmer Time ' 'Total Melt ' 'Glacier thickness ' >> $HOMEDIR_MISOMIP/COUPLED_Run.db
fi

if [ $BEGIN_COUPLED -gt 0 ];
then
  echo 'Coupled_iter: ' $BEGIN_COUPLED >> $HOMEDIR_MISOMIP/COUPLED_Run.db
fi

if [ $END_NEMO -gt 0 ];
then
  OUTPUT_FILE_NEMO=$6
  STATUS_RUN=$(tail -2 $OUTPUT_FILE_NEMO | head -1)

  if [ $STATUS_RUN == 'AAAAAAAA' ];
  then
	echo '  NEMO_iter: ' $END_NEMO ' DONE' >> $HOMEDIR_MISOMIP/COUPLED_Run.db
  else
	echo '  NEMO_iter: ' $END_NEMO ' CRASHED' >> $HOMEDIR_MISOMIP/COUPLED_Run.db
  fi
fi

if [ $END_ELMER -gt 0 ];
then
  OUTPUT_FILE=$5
  if grep -q 'Elmer Solver: ALL DONE' $OUTPUT_FILE; then
      STATUS_RUN=1
      echo '  ELMER_iter: ' $END_ELMER ' DONE' >> $HOMEDIR_MISOMIP/COUPLED_Run.db
  else
      STATUS_RUN=0
      echo '  ELMER_iter: ' $END_ELMER ' CRASHED' >> $HOMEDIR_MISOMIP/COUPLED_Run.db
  fi
fi

if [ $END_COUPLED -gt 0 ];
then
	OUTPUT_FILE=$5

	if grep -q 'Elmer Solver: ALL DONE' $OUTPUT_FILE; then
   		STATUS_RUN=1
	else
   		STATUS_RUN=0
	fi

	TIME=$( awk '/Time:/ {print $4}' $OUTPUT_FILE | tail -1 )

	MELT_RATE=$( awk '/TOTAL_MELT_RATE:/ {print $3}' $OUTPUT_FILE | tail -1 )

	THICKNESS=$( awk '/thickness/ {print $6}' $OUTPUT_FILE | tail -1 )


	echo '  Coupling details: ' 'time: ' $TIME 'Melt rate integral: ' $MELT_RATE 'Glacier thickness: '  $THICKNESS >> $HOMEDIR_MISOMIP/COUPLED_Run.db
	if [ $STATUS_RUN == 1 ];
	then 
	   exit 0
	else
	   exit -1
	fi

fi

echo 'eyy'

exit 0
