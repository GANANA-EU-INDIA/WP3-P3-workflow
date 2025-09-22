WORKFLOWNAME = md
NODES = 2
CPUS_PER_NODE = 32

# Usage: make (for more info, see .script/enqueue_submit.sh --help)
md:
	./scripts/enqueue_submit.sh $(WORKFLOWNAME) $(NODES) $(CPUS_PER_NODE)

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

.PHONY: clean, md