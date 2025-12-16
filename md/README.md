# MD Workflow with Gromacs

Workflow for a MD simulation based on the official [GROMACS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html), [zenodo link](https://zenodo.org/records/14803238).

Features:
- PyCOMPSs as Workflow Management System
- integration with Slurm (using alla available resourses)
- checkpoints for resilience against failures and re-runs
- data provenance

Todo:
- explicit specification in case of failed run


## How to use this repo

1. Fork this repo:
    ```bash
    git clone https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow.git
    ```
2. Install [(Py)COMPSs](./../docs/PyCOMPSs.md) and the required [Python environment](#setup-python-environment) in the HPC system
3. [Adapt the workflow](#adapt-the-workflow) and [the configuration files according](#configuration) to your needs
4. [Run the workflow](#usage)


## Setup Python environment

> [!NOTE]
> Tested with Python 3.11.x

Firstly, you need PyCOMPSs installated, see [installation docs](./../docs/PyCOMPSs.md).

Secontly, create a Python virtual environment usint the specification file [`requirements.txt`](./requirements.txt) using the built-in `venv` or [`uv`](https://github.com/astral-sh/uv); `conda` or its forks can be used but you are required to modify `wrapper/env_config.sh` to activate it. Within a cluster, a Python module is assumed to be loaded or, in any case, the interpreter being available.

An example using the Python stanrdard library:
```bash
# pwd -> WP3-P3-workflow/md
python -m venv ./md_env
. ./md_env/bin/activate # choose your shell of use
python -m pip install -r requirements.txt
```
> [!NOTE]
> When launching a workflow, Python environment activation is controlled by `wrapper/env_config.sh`. The name and location suggested above are the default ones that can be found in the latter bash file.
> If you use non-default name or location, be sure to update the bash script accordingly.


## Adapt the workflow

References:
- [PyCOMPSs quickstart](https://compss-doc.readthedocs.io/en/stable/Sections/00_Quickstart.html)
- [PyCOMPSs application development](https://compss-doc.readthedocs.io/en/stable/Sections/02_App_Development/02_Python.html)
- [Example of a Lysozyme in water MD simulation setup with PyCOMPSs](https://compss-doc.readthedocs.io/en/stable/Sections/07_Sample_Applications/02_Python/05_Lysozyme_in_water.html)

The central file to describe the Workflow is the Python script(s) inside `./workflow`.
To start developing your pipeline, modify this file describing the task to be executed through Python functions and PyCOMPSs decorators and develop the logic of your workflow.

The [configuration section](#configuration) describes the other files used to control and execute the workflow.


## Usage

### Submit a workflow
Using default arguments:
```bash
make name-workflow
```

Using custom arguments:
```bash
make NODES=4
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

In the above table, the higher the level the deep in the tree of calls is the file. Ideally, the end user has to modify only the Python workflow script (level 2) and the files related to this (such as the provenance, level 3).

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


### Example on how to modify level `<= 1`: implement new COMPSs arguments
Firstly, decide whether the argument is specified in the `Makefile` or in the `env_config.sh`

`Makefile`
1. Update the `Makefile` adding the argument on top and on the wrapper call
2. Modify `submit_workflow.sh` to catch the new argument from the command line (attention to the sanity checks), add description and add it to the other variables
3. In the same file, add the argument to the `enqueue_compss` call

`env_config.sh`
1. update the file in the relevant section
2. In `submit_workflow.sh`, add the argument to the `enqueue_compss` call