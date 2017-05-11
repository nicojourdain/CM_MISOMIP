run=PRUEBA
mesh=Mesh
name=Run0
#Either Domain, either Flat either DomainCSV, either Ice1
Type=Ice1
#Only used when Type=Ice1
PATH_RESTART=/scratch/cnt0021/gge6066/imerino/MISMIP+
caseTest=Test500m_Schoof_SSAStar
nameRestart=Run0

numParts=24
nodes=1

HomePath=/home/imerino/CM_MISOMIP
WorkPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP
RUN_NEMO=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/PRUEBA
RUN_ELMER=$WorkPath

ExecPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Executables/
ResultsPath=../Results/$name/
OutputPath=../Results/$name/
MeshPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA

mkdir -p $MeshPath/Results/$name

ln -sf $PATH_RESTART/$caseTest/Results/$nameRestart $MeshPath/RESTART
echo $PATH_RESTART/$caseTest/Results/$nameRestart
Restart=../RESTART/$nameRestart.result
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

###############CINES slurmScketch=$HomePath/Templates/Slurm/launchSck.slurm
slurmScketch=launchSck_cines.slurm
slurmFile=launchInit.slurm


tasks=$numParts
timeJob=00:15:00
jobName=$name
cp -r $PATH_RESTART/$caseTes/$mesh $MeshPath/

cat $slurmScketch | sed -e "s#<jobName>#$jobName#g" \
                        -e "s#<nodes>#$nodes#g" \
                        -e "s#<tasks>#$tasks#g" \
                        -e "s#<RUN>#$run#g" \
                        -e "s#<RUN_ELMER_PATH>#$RUN_ELMER#g" \
                        -e "s#<RUN_NEMO_PATH>#$RUN_NEMO#g" \
                        -e "s#<time>#$timeJob#g" > $slurmFile
#CINES affichage du fichie de soumission slurm
echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
cat $slurmFile
echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
source $HOMEDIR/scriptModulesELMER.sh
echo "xxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "xxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "Soumission du premier job launchInit.slurm"
#CINES affichage du fichie de soumission slurm
echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
cat $slurmFile
echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "xxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "xxxxxxxxxxxxxxxxxxxxxxxxxx"
sbatch $slurmFile 1

