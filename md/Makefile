WORKFLOWNAME = md
NODES = 1
CPUS_PER_NODE = 32
EXEC_TIME = 20
GRES_GPUS = 1

# Usage: make
help:
	@echo ""
	@echo "To execute the workflow, just type \"make ${WORKFLOWNAME}\". Other arguments:"
	@echo ""
	@./wrapper/submit_workflow.sh --help

$(WORKFLOWNAME):
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

clean: clean-except-rocrate
	rm -f -r COMPSs_RO-Crate*

.PHONY: help, $(WORKFLOWNAME), clean-except-rocrate, clean