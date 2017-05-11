run=HOLA
mesh=Mesh
name=Run0
#Either Domain, either Flat either DomainCSV, either Ice1
Type=Ice1
#Only used when Type=Ice1
caseTest=Test500m_Schoof_SSAStar
nameRestart=Run0

numParts=24
nodes=1

HomePath=/home/imerino/CM_MISOMIP+
WorkPath=/scratch/cnt0021/gge6066/imerino/MISOMIP_ELMER
RUN_NEMO=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/HOLA
RUN_ELMER=$WorkPath

ExecPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/HOLA/Executables/
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/HOLA
FileSource=$HomePath/DomainSources/MISMIP+_Domain_1km.nc

Restart=../../$caseTest/Results/$nameRestart/$nameRestart.result
RestartPosition=0

sifName=$name.sif
ScketchPath=$HomePath/Templates/Sif/
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

slurmScketch=$HomePath/Scketches/launchSck.slurm
slurmFile=launchInit.slurm


tasks=$numParts
timeJob=00:15:00
jobName=$name
cp -r $WorkPath/$caseTest/$mesh $MeshPath/
mkdir $WorkPath/$run/$mesh/$ResultsPath/
mkdir $WorkPath/$run/$mesh/$OutputPath/

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<RUN_ELMER_PATH>#$RUN_ELMER#g" \
                        -e "s#<RUN_NEMO_PATH>#$RUN_NEMO#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile

sbatch $slurmFile

