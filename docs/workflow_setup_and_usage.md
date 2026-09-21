# Setup and usage of `md` workflow

Instruction to use [`WP3-P3-workflow/md`](./../md/).

## Setup

This guide assumes that you have [PyCOMPSs installed](./../docs/PyCOMPSs.md).

1. Fork this repo:
   ```bash
   git clone https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow.git
   ```
2. Setup [Python environment](#setup-python-environment)
3. [Adapt the workflow and configure execution environment](#adapt-the-workflow)
4. [Run the workflow](#usage)

### Python environment

Load the same Python that was used to install PyCOMPSs; if you followed the Spack recipie, load the compss module with the Python interpreter as dependency. The precise procedure changes from cluster to cluster, it can be as simple as `ml compss`. Then, create a Python virtual environment using:

```bash
python -m venv ../envs/<venv_name> --system-site-packages
. ../envs/<venv_name>/bin/activate
```

`--system-site-packages` is fundamental to make the pycompss package available when the venv is sourced.

Add to the [`requirements.txt` file](./requirements.txt) the Python packages required by your workflow. Then, install them:

```bash
python -m pip install -r requirements.txt
```
`uv` or `conda` can be used too.

To use the Free Energy workflow, install `pmx` in the same venv:
```bash
git clone -b develop --depth=2 https://github.com/deGrootLab/pmx
cd pmx
git checkout develop # use the python 3 version
sed -i '/setup_requires=\["setuptools~=46\.0\.0"\]/d' setup.py
pip install .
```
The `sed` command removes an old setup requirement that might make the installation fail with recent `setuptools` versions.

!!! info
      For more info on how this environment is sourced before execution, see [`./wrapper/env_config_<cluster>.sh`](./wrapper/env_config_leonardo.sh). The venv name should match the workflow name (e.g., `md_env` for `md.py`) for automatic sourcing.

### Adapt the workflow

Typically, one starts modifying the Python scripts in [`workflow`](./workflow/) in which a high-level description of the workflow divided in tasks is detailed.
After that, one specifies the environment in which the workflow will be executed. The latter is controlled by bash scripts in [`wrapper`](./wrapper/) and the [`Makefile`](./Makefile).

The procedure is usually the following:

1. **Workflow definition**: define a Python script controlling the main pipeline. The tasks involved in the workflow can be defined in the same file or in separate ones. All these are stored in [`workflow`](./workflow/). The main Python file has a name that will be used to call PyCOMPSs. In this repo, tasks and pipeline are detailed inside [`workflow/md.py`](./workflow/md.py). Hence, the name of the workflow is `md`.
2. **Setup the execution environment**: open [`wrapper/env_config_<cluster>.sh`](./wrapper/env_config_leonardo.sh) and customize Slurm variables, modules to load before execution and everything to prepare the shell for workflow execution. This bash is sourced before launching `enqueue_compss`, which is called in [`wrapper/submit_workflow.sh`](./wrapper/submit_workflow.sh). Customize the latter to adjust `enqueue_compss` flags.

More information on the files used to control and execute the workflow can be found in the [configuration section](#configuration).

??? info "Some references to get started with PyCOMPSs"
      - [PyCOMPSs quickstart](https://compss-doc.readthedocs.io/en/stable/Sections/00_Quickstart.html#write-your-first-app)
      - [PyCOMPSs application development](https://compss-doc.readthedocs.io/en/stable/Sections/02_App_Development/02_Python.html)
      - [Example of a Lysozyme in water MD simulation setup with PyCOMPSs](https://compss-doc.readthedocs.io/en/stable/Sections/05_Sample_Applications/02_Python/05_Lysozyme_in_water.html)

## Usage

### Submit a workflow

Using default arguments:

```bash
make md
```

Using custom arguments:

```bash
make CLUSTERNAME=leonardo NODES=4 INPUT_DIR=./data/inputs
```

Just type `make` to have more info or inspect the `Makefile`.

!!! info "Input directory structure"
    The workflow expects input directories organized as follows:
    ```
    dataset/
    ├── protein1/
    │   ├── structure.pdb
    │   ├── select.txt
    │   ├── emin-charmm.mdp
    │   ├── nvt-charmm.mdp
    │   ├── npt-charmm.mdp
    │   └── md-charmm.mdp
    ├── protein2/
    │   ├── structure.pdb
    │   ├── select.txt
    │   ├── emin-charmm.mdp
    │   ├── nvt-charmm.mdp
    │   ├── npt-charmm.mdp
    │   └── md-charmm.mdp
    ```
    Each protein directory must contain:
    - One PDB file (the input structure)
    - `select.txt` (selection file for `pdb2gmx`, see examples/)
    - MD parameter files: `emin-charmm.mdp`, `nvt-charmm.mdp`, `npt-charmm.mdp`, `md-charmm.mdp`

### Remove output files

```bash
make clean
```

## Monitor workflow execution

To monitor a running workflow **locally**, use the [COMPSs Monitor Runner](./run_compss_monitor.md). Hence, from your local machine (_not the cluster!_):

```bash
./tools/run_compss_monitor.sh <cluster> <remote_parent_path>
./tools/run_compss_monitor.sh --stop
```

## Repository structure

Since this is a custom approach in executing PyCOMPSs workflows, this table summarizes the role of each file in the workflow definition and execution.
Levels represent the order of call when submitting a workflow (or, alternatively, the "distance" between the user issuing `make` and the workflow definition).

| level | file                                | description                                                                                                                           | For more info  | Target                   |
| ----- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------ |
| 0     | `Makefile`                          | Interface to easily handle workflow submission. Arguments that change often can be passed directly to `make`                          | type `make`    | Wrapper                  |
| 1     | `./wrapper/submit_workflow.sh`      | Wrapper to the `enqueue_compss` program.                                                                                              | type `make`    | PyCOMPSs                 |
| 1     | `./wrapper/env_config_<cluster>.sh` | Configuration file sourced by `submit_workflow.sh`. This bash describes the shell environment in which the workflow will be executed. | Check the file | Shell environment, Slurm |
| 2     | `./workflow/md.py`                  | Tasks and pipeline implementation. This file controls the whole workflow.                                                             | Check the file | Workflow                 |
| 3     | `./workflow/md-provenance.yaml`     | Configuration for Data Provenance.                                                                                                    | Check the file | Workflow                 |

In this setup, the workflow is managed through a `Makefile`.
The arguments that change often (such as input/output directories, number of cores per task, workflow name etc) are passed directly to `make` while more "stable" arguments are configured in `./wrapper`.
The main files for the workflow specification are stored inside `./wrapper/env_config_<cluster>.sh` and `./wrapper/submit_workflow.sh`.

!!! warning
      Currently, not all Slurm/COMPSs arguments are wrapped. See [`submit_workflow.sh`](./wrapper/submit_workflow.sh) for the full list of supported arguments.

      All arguments that are not set either in `make` nor `env_config.sh` use the default values as expressed in the COMPSs queue config file `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`. See [COMPSs documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/03_Configuration/02_Supercomputer.html) for more info.

## Development

### Wrap a Slurm/COMPSs argument

Example on how to modify level `<= 1`: implement a new COMPSs argument.
Firstly, decide whether the argument has to be specified at the `Makefile` level or at the `env_config_<cluster>.sh` level. In the two cases:

`Makefile`

1. Update the `Makefile` adding the argument on top and on the wrapper call
2. Modify `submit_workflow.sh` to catch the new argument from the command line (attention to the sanity checks), add description and add it to the other variables
3. In the same file, add the argument to the `enqueue_compss` call

`env_config_<cluster>.sh`

1. Update the file in the relevant section
2. In `submit_workflow.sh`, add the argument to the `enqueue_compss` call
