run=PRUEBA
numParts=24

#num=$(tail -1 Run.db | awk '{print $1}')
#number=${num:5:7}

number=$1

mesh=Mesh
nameRestart=Ice1r$number

if [ $number -gt 1 ]; then
	nameRestart=Ice1r$((number - 1 ))
else
	nameRestart=Run0
fi

name=Ice1r$number
echo $name

HomePath=/home/imerino/CM_MISOMIP
WorkPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP

RUN_NEMO=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/PRUEBA
RUN_ELMER=$WorkPath

#ExecPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Executables/
ExecPath=./Executables
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA
mkdir -p $MeshPath/Results/$name

ln -sf $WorkPath/$run/Results/$nameRestart $MeshPath/RESTART
Restart=../RESTART/$nameRestart.result
RestartPosition=0

sifName=$name.sif
ScketchPath=$HomePath/Templates/Sif/
scketch=$ScketchPath/scketchIce1r_SSAStar_fromNEMO.sif


outIntervals=6
Intervals=6
TimeStep=0.1

NRUN_MAX=3

C=1.0e-2
eta=0.2924017738212866
accum=0.3
CCou=0.5
MeltRate=-0.2


if [ $NRUN_MAX -lt $1 ]
then
	stop
fi

cat $scketch | sed -e "s#<ResultsPath>#$ResultsPath#g" \
                 -e "s#<MeshPath>#$MeshPath#g" \
                 -e "s#<Restart>#$Restart#g" \
                 -e "s#<ExecPath>#$ExecPath#g" \
                 -e "s#<RestartPosition>#$RestartPosition#g" \
                 -e "s#<meltRate>#$MeltRate#g" \
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
timeJob=09:50:00
jobName=$name
#################CINES slurmScketch=$HomePath/Templates/Slurm/launchSck.slurm
slurmScketch=launchSck_cines.slurm

#################CINES slurmFile=launchExec.slurm
slurmFile=launchExec_cines.slurm
jobLimit=3

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<jobLimit>#$jobLimit#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<RUN>#$run#g" \
                        -e "s#<RUN_ELMER_PATH>#$RUN_ELMER#g" \
                        -e "s#<RUN_NEMO_PATH>#$RUN_NEMO#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile


#source $HOMEDIR/.bash_profile

echo "CHECK JOBID"
echo $2
sbatch --parsable --dependency=afterany:$2 $slurmFile $(( number +1 ))

