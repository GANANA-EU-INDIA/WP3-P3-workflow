CLUSTERNAME = leonardo
# Prefer absolute paths
INPUT_DIR = $(shell pwd)/examples/from_modelling/input
OUTPUT_DIR = $(shell pwd)/examples/from_modelling/output
NODES = 1
CPUS_PER_NODE = 32
EXEC_TIME = 60
GRES_GPUS = 2

WORKFLOWS := $(basename $(notdir $(wildcard workflow/*.py)))

# Usage: make
help:
	@echo ""
	@echo "To execute the workflow, just type \"make ${WORKFLOWNAME}\". Other arguments:"
	@echo ""
	@./wrapper/submit_workflow.sh --help

$(WORKFLOWS):
	./wrapper/submit_workflow.sh $@ $(CLUSTERNAME) $(INPUT_DIR) $(OUTPUT_DIR) $(NODES) $(CPUS_PER_NODE) $(EXEC_TIME) $(GRES_GPUS)

clean-except-rocrate:
	rm -f compss*
	rm -f App_Profile.json
	rm -rf $(OUTPUT_DIR)/*
	rm -rf .COMPSs/*
	rm -rf .COMPSs
	rm -rf $(OUTPUT_DIR)/.COMPSs
	rm -rf tmp*
	rm -rf $(OUTPUT_DIR)/tmp*
	rm -rf $(OUTPUT_DIR)/.checkpoints
	rm -f $(INPUT_DIR)/*.{itp,gro,top}

clean: clean-except-rocrate
	rm -f -r COMPSs_RO-Crate*

.PHONY: help, $(WORKFLOWNAME), clean-except-rocrate, clean
