#!/bin/bash


#### JOB NAME
#SBATCH -J Ice1r1

#### RESSOURCES: Here 10 nodes (i.e. 240 cores) (each node as 24 cores)
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --constraint=BDW28
##SBATCH --constraint=HSW24
#SBATCH --exclusive

####  TIME
#SBATCH --time=09:50:00

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
./scriptAfterRun.sh Ice1r1

iter=$( awk '/Time:/ {print $3}' output.out | tail -1 )
iter=$((iter / 100 ))
echo $iter

timea=$(awk '/Time:/ {print $4}' output.out | tail -1)
echo $timea

mv /scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Mesh/*vtu /scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Results/Ice1r1
echo $1 $iter $timea >> Run_ELMER.db

PATH_NEMO_RUN=/scratch/cnt0021/gge6066/imerino/NEMO_MISOMIP/run/PRUEBA

LAST_ELMER_OUTPUT="$(ls -t /scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Results/Ice1r1/*pvtu | head -1)"

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
