# AGENTS.md

## Stack
PyCOMPSs (HPC workflows), GROMACS (`gmx_mpi`), Python 3.11+, Bash, Slurm, Spack.

## Commands
```bash
# Install PyCOMPSs
COMPSS_SUPERCOMPUTER_CFG=leonardo.cfg spack install compss && module load compss

# Run workflow
cd md/ && make md                              # or: make CLUSTERNAME=dardel NODES=4
make clean                                     # remove outputs

# Python env (--system-site-packages exposes PyCOMPSs)
python -m venv ../envs/<name> --system-site-packages
source ../envs/<name>/bin/activate && pip install -r requirements.txt
```

## Structure
```
md/
├── Makefile                    # entry point
├── wrapper/
│   ├── submit_workflow.sh      # calls enqueue_compss
│   └── env_config_<cluster>.sh # modules, venv, env vars
├── workflow/
│   ├── md.py                   # @task, @binary, @mpi decorators
│   └── md-provenance.yaml      # data provenance
├── data/                       # force fields, inputs
└── examples/                   # test I/O
```

## Code Style
```python
from pycompss.api.task import task
from pycompss.api.binary import binary
from pycompss.api.parameter import FILE_IN, FILE_OUT

@binary(binary="gmx_mpi", args="grompp -f {{mdp}} -c {{s}} -p {{t}} -o {{out}}")
@task(mdp=FILE_IN, s=FILE_IN, t=FILE_INOUT, out=FILE_OUT)
def preprocess(mdp=None, s=None, t=None, out=None) -> None:
    pass
```
- Python: `ruff format file.py` | Bash: `#!/bin/bash -e` | Let errors propagate

## Boundaries
- 🚫 Never commit secrets or modify `env_config_*.sh` blindly
- 🚫 Never modify workflow files (`md/workflow/md.py`) without explicit user approval
- ⚠️ Ask before changing Slurm queue/QOS or `Makefile` targets
- ✅ Safe: `docs/`, examples, `requirements.txt`, typos

## Git
Branches: `feat/`, `fix/`, `docs/`. Commits: `feat: add NPT task`. PR to `main`.

## Clusters
**Leonardo:** `ml compss && ml gromacs`, export `GMX_GPU_DD_COMMS=true`
**Dardel:** uses `env_config_dardel.sh`

## When in Doubt
1. Read `docs/workflow_setup_and_usage.md`
2. Check [PyCOMPSs docs](https://compss-doc.readthedocs.io/en/stable/index.html) for examples/troubleshooting
3. Copy patterns from `md/workflow/md.py`
4. Ask before cluster config changes
