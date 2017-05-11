CC=mpicc
#CCFLAG=-fPIC
CCFLAG=

NN_HOME=/home/imerino/CODES/nn-c/nn
CS_HOME=/home/imerino/CODES/csa
NNLIB=$(NN_HOME)/libnn.a
CSLIB=$(CS_HOME)/libcsa.a

#NETCDF INCLUDE and LIBS Flags
NETCDFHOME=/opt/software/occigen/libraries/netcdf/4.4.0_fortran-4.4.2/hdf5/1.8.17/intel/17.0/openmpi/intel/2.0.1/
#NETCDFHOME=/opt/software/libraries/netcdf/4.3.3-rc2_fortran-4.4.1/hdf5/1.8.14/intel/16.0.1.150/intelmpi/5.1.2.150
NETCDFINC="-I$(NETCDFHOME)/include"
NETCDFLIBS="-L$(NETCDFHOME)/lib -lnetcdff -lnetcdf"

ELMERICE_SRC=/home/imerino/elmerice/Solvers/
ELMERICE_USF=/home/imerino/elmerice/UserFunctions
SOLVERS_SRC=/panfs/panasas/cnt0021/gge6066/imerino/MyElmerSolvers/
ExecPath=/scratch/cnt0021/gge6066/imerino/ELMER_MISOMIP/PRUEBA/Executables/

SOLVERS_LIST=$(SOLVERS_SRC)/SSAStar.F90 \
        $(SOLVERS_SRC)/USF_MISMIP_Dom.F90 \
        $(ELMERICE_SRC)/Flotation.F90\
        $(ELMERICE_SRC)/EffectivePressure.F90\
        $(SOLVERS_SRC)/ThicknessSolver_Alpha.F90 \
        $(ELMERICE_USF)/USF_WaterPressure.F90 \
	$(SOLVERS_SRC)/MISOMIP_Melt.F90


solvers := $(filter %,$(patsubst %.F90,%,$(notdir $(SOLVERS_LIST)))) $(filter %,$(patsubst %.F90,%,$(LOCAL_SOLVERS)))

#GridDataReader: $(SOLVERS_SRC)/GridDataReader.F90
#	elmerf90 $< $(NETCDFF_INC) $(NETCDFF_LDFLAGS) -o $(ExecPath)/GridDataReader

all: $(solvers)

%: $(SOLVERS_SRC)/%.F90
	elmerf90  $< -o $(ExecPath)/$@

%: $(ELMERICE_SRC)/%.F90
	elmerf90  $< -o $(ExecPath)/$@

%: $(ELMERICE_USF)/%.F90
	elmerf90  $< -o $(ExecPath)/$@

%:%.F90
	elmerf90  $< -o $(ExecPath)/$@

MISOMIP_Melt: $(SOLVERS_SRC)/MISOMIP_Melt.F90
	elmerf90 $< $(NETCDFINC) $(NETCDFLIBS) -o $(ExecPath)/MISOMIP_Melt
clean:
	rm -f $(solvers)
