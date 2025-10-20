# MD Workflow with Gromacs

Workflow for a MD simulation based on the official [GROMACS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html), [zenodo link](https://zenodo.org/records/14803238).

Branch `example-3vxm-kth` contains an example of workflow starting from a single structure already preprocessed with pdb2gmx due to a problme in selecting charged protein chains ends.

Features:
- PyCOMPSs as Workflow Management System
- integration with Slurm (using alla available resourses)
- checkpoints for resilience against failures and re-runs
- data provenance

Todo:
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
### Submit a workflow
Using default arguments:
```bash
make name-workflow
```

Using custom arguments:
```bash
NODES=4 make
```
Just type `make` to have more info.

### Remove produced files
```bash
make clean
```

## Configuration

| level | file                            | description                                                                                                                                                      | For more info  | Target                           |
|-------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|----------------------------------|
| 0     | `Makefile`                      | Interface to easily handle workflow submission. Arguments that changes often can be passed directly to `make`                                                    | type `make`    | Wrapper                          |
| 1     | `./wrapper/submit_workflow.sh`  | Wrapper to the `enqueue_compss` program.                                                                                                                         | type `make`    | Shell environment, Slurm, COMPSs |
| 1     | `./wrapper/env_config.sh`       | Configuration file sourced by `submit_workflow.sh`. Here you change arguments that tends to remain stable across workflow executions. This is the one to modify. | Check the file | Shell environment, Slurm, COMPSs |
| 2     | `./workflow/md.py`              | Implementation of the tasks and pipeline. This is the file controlling the whole workflow.                                                                       | Check the file | Workflow                         |
| 3     | `./workflow/md-provenance.yaml` | Configuration for Data Provenance.                                                                                                                               | Check the file | Workflow                         |

In this setup, the workflow is managed through a `Makefile`.
The arguments that change often (such as number of core per task, workflow name etc) are passed directly to `make` while other rarely changes arguments are configured in `./wrapper`.
The main files for the workflow specification are store inside `./workflow`.

The "chain of calls" is the following:
```bash
Makefile
└── wrapper/submit_workflow.sh
    ├── wrapper/env_config.sh
    └── enqueue_compss
```
> [!WARNING]
> Currently, not all Slurm/COMMPs arguments are wrapped.

> [!WARNING]
> All arguments that are not set either in `make` nor `env_config.sh` use the default values as expressed in the COMPSs queue config file `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`

Files related to COMPSs and workflow configuration:
- The queue config file (by defaul stored in `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`)
- The provenance config file
More info can be found in the [official COMPSs documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/06_Configuration_files.html#configuration-files). Note that there are other config file that can be used to control the behavior of COMPSs during execution. These are the resource and project xml files. In this project, we try to explicitely define the needed arguments in the `enqueue_compss` call, leaving these config files in their deafult state (see your COMPSs installation).

## Development

The development environment is the same as the one used to submit and execute the workflows.
In the [configuration](#configuration) section an explanation of the general structure of the software is detailed.
Below some common dev topics.

### Implement new COMPSs arguments
Firstly, decide whether the argument is specified in the `Makefile` or in the `env_config.sh`

`Makefile`
1. Update the `Makefile` adding the argument on top and on the wrapper call
2. Modify `submit_workflow.sh` to catch the new argument from the command line (attention to the sanity checks), add description and add it to the other variables
3. In the same file, add the argument to the `enqueue_compss` call

`env_config.sh`
1. update the file in the relevant section
2. In `submit_workflow.sh`, add the argument to the `enqueue_compss` call