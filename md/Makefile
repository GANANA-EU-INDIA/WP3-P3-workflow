WORKFLOWNAME = md
NODES = 2
CPUS_PER_NODE = 32
EXEC_TIME = 20
GRES_GPUS = 1

# Usage: make
help:
	@echo ""
	@echo "To execute the workflow, just type \"make ${WORKFLOWNAME}\". Other arguments:"
	@echo ""
	@./scripts/enqueue_submit.sh --help

$(WORKFLOWNAME):
	./scripts/enqueue_submit.sh $(WORKFLOWNAME) $(NODES) $(CPUS_PER_NODE) $(EXEC_TIME) $(GRES_GPUS)

clean:
	rm -f compss*
	rm -f App_Profile.json
	rm -f -r COMPSs_RO-Crate*
	rm -rf data/output/*
	rm -rf .COMPSs/*
	rm -rf .COMPSs
	rm -rf data/.COMPSs
	rm -rf tmp*
	rm -rf data/tmp*
	rm -rf data/.checkpoints

.PHONY: help, $(WORKFLOWNAME), clean