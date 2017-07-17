
CALL_NEMO=$1
run=<run>
mesh=Mesh
name=Run0
#Either Domain, either Flat either DomainCSV, either Ice1
Type=Ice1
#Only used when Type=Ice1
PATH_RESTART=<path_restart>
caseTest=<caseTest>
nameRestart=<RunRestart>

numParts=<numParts>
nodes=<numNodes>

HomePath=<HOMEDIR_MISOMIP>
WorkPath=<WORKDIR_ELMER>
RUN_NEMO=<NEMO_RUN>
RUN_ELMER=$WorkPath

ExecPath=<Executables>
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=<MeshNamePath>

mkdir -p $MeshPath/Results/$name

rm -r $MeshPath/RESTART
ln -sf $PATH_RESTART/$caseTest/Results/$nameRestart $MeshPath/RESTART
echo $PATH_RESTART/$caseTest/Results/$nameRestart
Restart=../RESTART/$nameRestart.result
RestartPosition=0

sifName=$name.sif
ScketchPath=$HomePath/../../Templates/Sif/
scketch=$ScketchPath/scketchInit$Type.sif

cat $scketch | sed -e "s#<FileSource>#$FileSource#g" \
                 -e "s#<Restart>#$Restart#g" \
                 -e "s#<RestartPosition>#$RestartPosition#g" \
		 -e "s#<ResultsPath>#$ResultsPath#g" \
		 -e "s#<MeshPath>#$MeshPath#g" \
                 -e "s#<ExecPath>#$ExecPath#g" \
                 -e "s#<name>#$name#g" \
		 -e "s#<mesh>#$mesh#g" > $sifName

echo $sifName >> toto
mv toto ELMERSOLVER_STARTINFO

slurmScketch=$HomePath/../../Templates/Slurm/launchSck.slurm
slurmFile=launchInit.slurm


tasks=$numParts
timeJob=00:15:00
jobName=$name
cp -r $PATH_RESTART/$caseTest/$mesh $MeshPath/

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<RUN>#$run#g" \
                        -e "s#<RUN_ELMER_PATH>#$RUN_ELMER#g" \
                        -e "s#<RUN_NEMO_PATH>#$RUN_NEMO#g" \
                        -e "s#<MISOMIP_HOMEDIR>#$HomePath#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile

START_FROM_RST=$2
RST_FILE=$3

sbatch $slurmFile 1 $CALL_NEMO "DUMMY_MELT_FILE" $START_FROM_RST $RST_FILE 'INIT'

