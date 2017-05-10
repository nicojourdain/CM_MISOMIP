#!/bin/bash


#### JOB NAME
#SBATCH -J <jobName>

#### RESSOURCES: Here 10 nodes (i.e. 240 cores) (each node as 24 cores)
#SBATCH --nodes=<nodes>
#SBATCH --ntasks=<tasks>
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --constraint=BDW28
##SBATCH --constraint=HSW24
#SBATCH --exclusive

####  TIME
#SBATCH --time=<time>

##### OUTPUT FILES
#SBATCH --output MyJOB_SRUN.%j.output
#SBATCH --error MyJOB_SRUN.%j.error

######
export OMP_NUM_THREADS=1

#####
echo "Starting at `date`"
echo "Running on hosts: $SLURM_NODELIST"
echo "Running on $SLURM_NNODES nodes."
echo "Running on $SLURM_NPROCS processors."
echo "Current working directory is `pwd`"

#### RUN ELMER


WORKPATH=`pwd`

module list

#source $HOMEDIR/scriptModulesELMER.sh

#module list
PATH_NEMO_RUN=<RUN_NEMO_PATH>
MISOMIP_HOMEDIR=<MISOMIP_HOMEDIR>

START_FROM_RESTART=$4
RST_FILE=$5

PATH_MELT_FILE=$3
Melt_Rate_File="$(ls -t $PATH_MELT_FILE/*SBC* | head -1)"
echo "meltfile::"
echo $Melt_Rate_File

ln -sf $Melt_Rate_File $MISOMIP_HOMEDIR/melt_rates.nc

srun --mpi=pmi2 -K1 --resv-ports -n $SLURM_NTASKS ElmerSolver_mpi

mv <RUN_ELMER_PATH>/<RUN>/Mesh/*vtu <RUN_ELMER_PATH>/<RUN>/Results/<jobName>


echo "RUNfile::" $Melt_Rate_File
RUNFILE="$(ls -t $WORKPATH/*.output | head -1)"
$MISOMIP_HOMEDIR/read_write_Elmer_run_info.sh $RUNFILE
#echo $1 >> Run_ELMER.db

LAST_ELMER_OUTPUT="$(ls -t <RUN_ELMER_PATH>/<RUN>/Results/<jobName>/*pvtu | head -1)"

echo 'hola'
echo $LAST_ELMER_OUTPUT


$MISOMIP_HOMEDIR/scriptWriteISFDraft.sh $LAST_ELMER_OUTPUT $1

#source $HOMEDIR/scriptModulesNEMO.sh
#cd $PATH_NEMO_RUN
#jobid=$(sbatch --parsable run_nemo_ISOMIP.sh)

#cd $WORKPATH
#echo $WORKPATH
#source $HOMEDIR/scriptModulesELMER.sh
#./scriptIce1rExecute.sh $1 $jobid

#If second argumnet == 1 we call NEMO



if [ $2 -eq 1 ]; then
   cd $PATH_NEMO_RUN
   jobid=$(sbatch --parsable run_nemo_ISOMIP.sh $START_FROM_RESTART $RST_FILE)
fi
