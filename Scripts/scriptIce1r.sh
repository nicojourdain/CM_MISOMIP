run=<run>
mesh=Mesh
name=Ice1r
echo $name
nameRestart=Run0
echo $nameRestart
host=lachouf2
numParts=<numParts>

HomePath=/home/imerino/CM_MISMIP+_MERINO/MISMIP+
WorkPath=/scratch/cnt0021/gge6066/imerino/MISMIP+
mkdir $WorkPath/$run/Results/$name

sifName=$name.sif
ScketchPath=$HomePath/Scketches/Sif/
scketch=$ScketchPath/scketchIce1r.sif

ExecPath=<Executables>
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=<MeshNamePath>

Restart=../Results/$nameRestart/$nameRestart.result
RestartPosition=0
outIntervals=100
Intervals=1000
TimeStep=0.1

#C=1.0e-2
#eta=0.2924017738212866
#accum=0.3
#CCou=0.5
#MeltRate=-0.2

cat $scketch | sed -e "s#<FileSource>#$FileSource#g" \
		 -e "s#<ResultsPath>#$ResultsPath#g" \
		 -e "s#<MeshPath>#$MeshPath#g" \
                 #-e "s#<meltRate>#$MeltRate#g" \
                 -e "s#<Restart>#$Restart#g" \
                 #-e "s#<CCou>#$CCou#g" \
                 -e "s#<ExecPath>#$ExecPath#g" \
                 -e "s#<RestartPosition>#$RestartPosition#g" \
                 -e "s#<outIntervals>#$outIntervals#g" \
                 -e "s#<Intervals>#$Intervals#g" \
                 -e "s#<TimeStep>#$TimeStep#g" \
                 #-e "s#<C>#$C#g" \
                 #-e "s#<eta>#$eta#g" \
                 #-e "s#<accum>#$accum#g" \
                 -e "s#<name>#$name#g" \
		 -e "s#<mesh>#$mesh#g" > $sifName

echo $sifName >> toto
mv toto ELMERSOLVER_STARTINFO


nodes=1
tasks=$numParts
timeJob=20:00:00
jobName=$name
slurmScketch=$HomePath/Scketches/launchSck.slurm
slurmFile=launchExec.slurm

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile

sbatch $slurmFile

