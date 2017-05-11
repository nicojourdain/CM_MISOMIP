

#source $HOMEDIR/scriptModulesNEMO.sh
cd $1
jobid=$(sbatch --parsable run_nemo_ISOMIP.sh)

module list

cd $WORKPATH
echo $WORKPATH
#source $HOMEDIR/scriptModulesELMER.sh
#./scriptIce1rExecute.sh $1 $jobid
