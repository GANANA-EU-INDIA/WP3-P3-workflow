# MD Workflow with Gromacs

Workflow for a MD simulation based on the official [GROMACS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html), [zenodo link](https://zenodo.org/records/14803238).

Features:
- PyCOMPSs as Workflow Management System
- integration with Slurm (using alla available resourses)
- checkpoints for resilience against failures and re-runs
- data provenance

## Use this repo

This guide assumes that you have [PyCOMPSs installed](./../docs/PyCOMPSs.md).

1. Fork this repo:
    ```bash
    git clone https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow.git
    ```
2. Setup [Python environment](#setup-python-environment)
3. [Adapt the workflow and configure execution environment](#adapt-the-workflow)
4. [Run the workflow](#usage)


### Setup Python environment

Load the same Python that was used to install PyCOMPSs; if you followed the Spack recipie, load the compss module with the Python interpreter as dependency. The precise procedure changes from cluster to cluster, it can be as simple as `ml compss`. Then, create a Python virtual environment using:
```bash
python -m venv ../envs/<venv_name> --system-site-packages
. ../envs/<venv_name>/bin/activate
```
> [!NOTE]
> `--system-site-packages` is fundamental to make the pycompss package available when the venv is sourced.

Add to the [`requirements.txt` file](./requirements.txt) the Python packages required by your workflow. Then, install them:
```bash
python -m pip install -r requirements.txt
```

> [!NOTE]
> For more info on how this environment is source before execution, see [`./wrapper/env_config.sh`](./wrapper/env_config.sh). As currently implemented, if the venv has the same name as the main Python script describing the workflow, the sourcing is easier. This behavior can be changed.

`uv` or `conda` can be used toos.


### Adapt the workflow

Typically, one starts modifying the Python scripts in [`workflow`](./workflow/) in which a high-level description of the workflow divided in tasks is detailed.
After that, one specifies the enviroment in which the workflow will be executed. Teh latter is controlled by bash scripts in [`wrapper`](./wrapper/) and the [`Makefile`](./Makefile).

The procedure is usually the follow:

1. **Workflow definition**: define a Python script controlling the main pipeline. The tasks involved in the workflow can be defined in the same file or in separate ones. All these are stored in [`workflow`](./workflow/). The main Python file has a name that will be used to call PyCOMPSs. In this repo, tasks and pipeline are detailed inside [`workflow/md.py`](./workflow/md.py). Hence, the name of the workflow is `md`[^1].
2. **Setup the execution environment**: open [`wrapper/env_config.sh`](./wrapper/env_config.sh) and customize Slurm variables, modules to load before execution and everything to prepare the shell to the workflow execution. This bash is sourced before lauching `enqueue_compss`, which is called in [`wrapper/submit_workflow.sh`](./wrapper/submit_workflow.sh). Customize the latter to adjust `enqueue_compss` flags.

More information on the files used to control and execute the workflow can be found in the [configuration section](#configuration).

[^1]: Some references to get started with PyCOMPSs:
    - [PyCOMPSs quickstart](https://compss-doc.readthedocs.io/en/stable/Sections/00_Quickstart.html#write-your-first-app)
    - [PyCOMPSs application development](https://compss-doc.readthedocs.io/en/stable/Sections/02_App_Development/02_Python.html)
    - [Example of a Lysozyme in water MD simulation setup with PyCOMPSs](https://compss-doc.readthedocs.io/en/stable/Sections/05_Sample_Applications/02_Python/05_Lysozyme_in_water.html)

### Usage

#### Submit a workflow
Using default arguments:
```bash
make name-workflow
```

Using custom arguments:
```bash
make NODES=4 INPUT_DIR=./data/inputs
```
Just type `make` to have more info.

#### Remove produced files
```bash
make clean
```


## Repository structure

Since this is a custom approch in executing PyCOMPSs workflows, this table summarize the role of each file in the workflow definition and execution.
Levels represent the order of call when submitting a workflow (or, alternatively, the "distance" between the user issueing `make` and the workflow definition).

| level | file                            | description                                                                                                                                                      | For more info  | Target                           |
|-------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|----------------------------------|
| 0     | `Makefile`                      | Interface to easily handle workflow submission. Arguments that changes often can be passed directly to `make`                                                    | type `make`    | Wrapper                          |
| 1     | `./wrapper/submit_workflow.sh`  | Wrapper to the `enqueue_compss` program.                                                                                                                         | type `make`    | PyCOMPSs |
| 1     | `./wrapper/env_config.sh`       | Configuration file sourced by `submit_workflow.sh`. This bash described the shell environment in which the workflow will be executed. | Check the file | Shell environment, Slurm |
| 2     | `./workflow/md.py`              | Tasks and pipeline implementation. This file controls the whole workflow.                                                                       | Check the file | Workflow                         |
| 3     | `./workflow/md-provenance.yaml` | Configuration for Data Provenance.                                                                                                                               | Check the file | Workflow                         |


In this setup, the workflow is managed through a `Makefile`.
The arguments that change often (such as input/output directories, number of core per task, workflow name etc) are passed directly to `make` while more "stable" arguments are configured in `./wrapper`.
The main files for the workflow specification are store inside `./wrapper/env_config.sh` and `./wrapper/env_config.sh`.


> [!WARNING]
> Currently, not all Slurm/COMPSs arguments are wrapped.

> [!WARNING]
> All arguments that are not set either in `make` nor `env_config.sh` use the default values as expressed in the COMPSs queue config file `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`. See [COMPSs documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/03_Configuration/02_Supercomputer.html) for more info.

## Development

### Wrap a Slurm/COMPSs argument
Example on how to modify level `<= 1`: implement a new COMPSs argument.
Firstly, decide whether the argument has to be specified at the `Makefile` level or at the `env_config.sh` level. In the two cases:

`Makefile`
1. Update the `Makefile` adding the argument on top and on the wrapper call
2. Modify `submit_workflow.sh` to catch the new argument from the command line (attention to the sanity checks), add description and add it to the other variables
3. In the same file, add the argument to the `enqueue_compss` call

`env_config.sh`
1. update the file in the relevant section
2. In `submit_workflow.sh`, add the argument to the `enqueue_compss` call