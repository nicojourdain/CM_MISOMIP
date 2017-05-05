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

srun --mpi=pmi2 -K1 --resv-ports -n $SLURM_NTASKS ElmerSolver_mpi
./scriptAfterRun.sh <jobName>

iter=$( awk '/Time:/ {print $3}' output.out | tail -1 )
iter=$((iter / 100 ))
echo $iter

timea=$(awk '/Time:/ {print $4}' output.out | tail -1)
echo $timea

mv <RUN_ELMER_PATH>/<RUN>/Mesh/*vtu <RUN_ELMER_PATH>/<RUN>/Results/<jobName>
echo $1 $iter $timea >> Run_ELMER.db

PATH_NEMO_RUN=<RUN_NEMO_PATH>

LAST_ELMER_OUTPUT="$(ls -t <RUN_ELMER_PATH>/<RUN>/Results/<jobName>/*pvtu | head -1)"

echo 'hola'
echo $LAST_ELMER_OUTPUT

#./scriptWriteISFDraft.sh $LAST_ELMER_OUTPUT $1

#source $HOMEDIR/scriptModulesNEMO.sh
#cd $PATH_NEMO_RUN
#jobid=$(sbatch --parsable run_nemo_ISOMIP.sh)

#cd $WORKPATH
#echo $WORKPATH
#source $HOMEDIR/scriptModulesELMER.sh
#./scriptIce1rExecute.sh $1 $jobid
#./scriptTEST.sh $PATH_NEMO_RUN
