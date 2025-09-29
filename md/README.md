# MD Workflow with Gromacs

Workflow for a MD simulation based on the official [GROMACS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html), [zenodo link](https://zenodo.org/records/14803238).

Features:
- PyCOMPSs as Workflow Management System
- integration with Slurm (using alla available resourses)
- checkpoints for resilience against failures and re-runs

Todo:
- data provenance
- explicit specification in case of failed run


## Installation

For the Python packages required, create a Python virtual env using (within a cluster, a Python module is assumed to be loaded):
```bash
python -m venv ../envs/md
. ../envs/md/bin/activate
python -m pip install -r requirements.txt
```
NOTE: the environment name has to match the name of the root directory in which this readme is in.

For the (Py)COMPSs installataion, see [the installation docs](../docs/).

## Usage

> **tl;dr How to control workflow execution**
> - Slurm arguments as `make` variables (see `enqueue_submit.sh --help`)
> - Other Slurm arguments in `slurm_config.sh`
> - Environment in `module_setup.sh`
> - PyCOMPSs config files for hardware specification
> - PyCOMPSs config file for Data Provenance
>

In this setup, the workflow is managed through a `Makefile`.
The arguments that change often (such as num of core per task, workflow file etc) are passed directly to `make` while other rarely changes arguments are configured with the scripts inside the `./scripts` directive.

The "chain of calls" is the following:
```bash
Makefile
└── scripts/enqueue_submit.sh
    ├── scripts/module_setup.sh
    └── scripts/slurm_config.sh
```
`module_setup` prepares the supercomputer environment to execute COMPSs by loading the required modules. `slurm_config` containes arguments to submit jobs with the Slurm scheduler.

Other COMPSs specific config files are:
- The queue config file (by defaul stored in `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`)
- The provenance config file
More info can be found in the [official COMPSs documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/06_Configuration_files.html#configuration-files).

### Preparation: modules, environments and paths

#### `./scripts/module_setup.sh`

Loads required modules to execute (Py)COMPSs and Gromacs.
Here we define some environmental variables required by these programs.

#### `./scripts/slurm_config.sh`

Bash variables that mirrors rarely changing Slurm arguments such as account name and the like.
This file containes a subset of Slurm arguments that are complemented by those handled by `make` (that forwards it to `enqueue_submit.sh`).
To have more details use `enqueue_submit.sh --help`.
> WARNING: not all Slurm arguments are wrapped.

> WARNING: all arguments that has not been set either in `make` nor `slurm_config.sh` uses the default values as expressed in the COMPSs queue config file `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`

### Submit a workflow

Using default arguments:
```bash
make
```

Using custom arguments:
```bash
NODES=4 make
```
