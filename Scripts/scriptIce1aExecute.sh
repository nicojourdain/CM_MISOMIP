run=<run>
numParts=<numParts>

#num=$(tail -1 Run.db | awk '{print $1}')
#number=${num:5:7}

number=$1

mesh=Mesh
nameRestart=Ice1a$number

if [ $number -gt 1 ]; then
	nameRestart=Ice1a$((number - 1 ))
else
	nameRestart=Run0
fi

name=Ice1r$number

HomePath=<HOMEDIR_MISOMIP>

WorkPath=<WORKDIR_ELMER>

RUN_NEMO=<NEMO_RUN>
RUN_ELMER=$WorkPath

ExecPath=<Executables>
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=<MeshNamePath>
mkdir -p $MeshPath/Results/$name

rm $MeshPath/RESTART
ln -sf $WorkPath/$run/Results/$nameRestart $MeshPath/RESTART
Restart=../RESTART/$nameRestart.result
RestartPosition=0

sifName=$name.sif
ScketchPath=$HomePath/../../Templates/Sif/
scketch=$ScketchPath/scketchIce1r_SSAStar_fromNEMO.sif


outIntervals=<OUTPUT_FREQ_ELMER>
Intervals=<INTERVALS_ELMER>
TimeStep=<TIME_STEP_ELMER>

NRUN_MAX=<NRUN_MAX>

C=1.0e-2
eta=0.2924017738212866
accum=0.3
CCou=0.5
MeltRate=-0.2  # not used for MISOMIP

CALL_NEMO=0
if [ $1 -lt $NRUN_MAX ]
then
	CALL_NEMO=1
fi

cat $scketch | sed -e "s#<ResultsPath>#$ResultsPath#g" \
                 -e "s#<MeshPath>#$MeshPath#g" \
                 -e "s#<Restart>#$Restart#g" \
                 -e "s#<ExecPath>#$ExecPath#g" \
                 -e "s#<RestartPosition>#$RestartPosition#g" \
                 -e "s#<meltRate>#$MeltRate#g" \
                 -e "s#<MELT_FILE>#$HomePath/melt_rates.nc#g" \
                 -e "s#<outIntervals>#$outIntervals#g" \
                 -e "s#<Intervals>#$Intervals#g" \
                 -e "s#<CCou>#$CCou#g" \
                 -e "s#<TimeStep>#$TimeStep#g" \
                 -e "s#<C>#$C#g" \
                 -e "s#<eta>#$eta#g" \
                 -e "s#<accum>#$accum#g" \
                 -e "s#<name>#$name#g" \
		 -e "s#<mesh>#$mesh#g" > $sifName

echo $sifName >> toto
mv toto ELMERSOLVER_STARTINFO


nodes=1
tasks=$numParts
timeJob=00:50:00  # SBATCH walltime for Elmer/Ice execution
#timeJob=09:50:00
jobName=$name
slurmScketch=$HomePath/../../Templates/Slurm/launchSck.slurm
slurmFile=launchExec.slurm

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<RUN>#$run#g" \
                        -e "s#<MISOMIP_HOMEDIR>#$HomePath#g" \
                        -e "s#<RUN_ELMER_PATH>#$RUN_ELMER#g" \
                        -e "s#<RUN_NEMO_PATH>#$RUN_NEMO#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile

jobidComp=$2
PATH_MELT_FILE=$3

sbatch --dependency=afterany:$jobidComp $slurmFile $(( number +1 )) $CALL_NEMO $PATH_MELT_FILE 0 "DUMMY_RST_FILE" $number


