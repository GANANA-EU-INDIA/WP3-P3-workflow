WORKFLOWNAME = md
NODES = 1
CPUS_PER_NODE = 32
EXEC_TIME = 20
GRES_GPUS = 1

# Preprocess done manually for haddock structure
ABSOLUTE_PATH_ROOT = /leonardo/home/userinternal/lsalicar/workflow/md
PROTEIN = 3VXM_3VXM.BL00030001_haddock.pdb
STRUCTURE = structure_processed.gro
TOPOLOGY = topology.top
FF = charmm36-jul2022
WATER = tip3p

# Usage: make
help:
	@echo ""
	@echo "To execute the workflow, just type \"make ${WORKFLOWNAME}\". Other arguments:"
	@echo ""
	@./wrapper/submit_workflow.sh --help

# Interactive pre-processing and call to COMPSs
.ONESHELL:
SHELL = /bin/bash
$(WORKFLOWNAME):
	@if [ ! -f "${ABSOLUTE_PATH_ROOT}/data/input/topology.top" ]; then \
		ml purge; \
		module use --append /leonardo/pub/userinternal/lsalicar/spack-0.22.2-06/modules; \
		ml gromacs/2024.6--openmpi--4.1.6--gcc--12.2.0-cuda-12.2; \
		cd ${ABSOLUTE_PATH_ROOT}/data/input; \
		GMXLIB=${ABSOLUTE_PATH_ROOT}/data GMXBIN_NAME="gmx_mpi" bash -i ${ABSOLUTE_PATH_ROOT}/workflow/scripts/pdb2gmx_wrapper.sh ${PROTEIN} ${STRUCTURE} ${TOPOLOGY} ${FF} ${WATER}; \
		cd ${ABSOLUTE_PATH_ROOT}; \
	fi
	./wrapper/submit_workflow.sh $(WORKFLOWNAME) $(NODES) $(CPUS_PER_NODE) $(EXEC_TIME) $(GRES_GPUS)

clean-except-rocrate:
	rm -f compss*
	rm -f App_Profile.json
	rm -rf data/output/*
	rm -rf .COMPSs/*
	rm -rf .COMPSs
	rm -rf data/.COMPSs
	rm -rf tmp*
	rm -rf data/tmp*
	rm -rf data/.checkpoints

clean-inputs:
	rm -f data/input/*.{itp,gro,top}

clean: clean-except-rocrate, clean-inputs
	rm -f -r COMPSs_RO-Crate*

.PHONY: help, $(WORKFLOWNAME), clean-except-rocrate, clean-inputs, clean