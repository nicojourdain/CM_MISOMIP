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
#SBATCH --output Sck.%j.outerr
#SBATCH --error Sck.%j.outerr

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
module purge
module load intel/15.6.233
module load intelmpi/5.1.3.258
module load szip/2.1
module load hdf5/1.8.14
module load netcdf/4.3.3-rc2_fortran-4.4.1
module load cmake
module list
echo " le repertoire courant est", `pwd`
which ElmerSolver_mpi
srun --mpi=pmi2 -K1 --resv-ports -n $SLURM_NTASKS `which ElmerSolver_mpi`
#
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
./scriptWriteISFDraft.sh $LAST_ELMER_OUTPUT $1

#exit
#----------------------exit
#----------------------exit
#----------------------exit
#####################Lancement de NEMO##########################
echo "###############Lancement de NEMO#########################"
source $HOMEDIR/scriptModulesNEMO.sh
cd $PATH_NEMO_RUN
jobid=$(sbatch --parsable run_nemo_ISOMIP.sh)

cd $WORKPATH
echo $WORKPATH
#source $HOMEDIR/scriptModulesELMER.sh
#####################Lancement du script Ice1rEexecute ##########################
echo "###############Preparation du Lancement du script Ice1rEexecute ####################"
#ajout CINES de la ligne module purge ici
module purge
module list
echo "###############Lancement du script Ice1rEexecute ####################"
cat ./scriptIce1rExecute_cines.sh 
./scriptIce1rExecute_cines.sh $1 $jobid

