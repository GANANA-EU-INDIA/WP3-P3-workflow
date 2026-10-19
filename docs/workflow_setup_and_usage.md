# Setup and usage of `md` workflow

These instructions describe the setup and the usage of the workflow [`WP3-P3-workflow/md`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md). This can be used directly or as a template for a new workflow.

## Setup

This guide assumes that you have [PyCOMPSs installed](./installation.md).

1. Fork this repo:
   ```bash
   git clone https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow.git
   ```
2. Setup [Python environment](#python-environment)
3. (Optional) [Adapt the workflow and configure execution environment](#adapt-the-workflow)
4. [Run the workflow](#usage)

### Python environment

Load the same Python that was used to install PyCOMPSs. If you followed the [installation](./installation.md), load the `compss` module with the Python interpreter as dependency. The precise procedure changes from cluster to cluster, it can be as simple as `ml compss`. Then, create a Python virtual environment using:

```bash
cd md
python -m venv .venv --system-site-packages
. .venv/bin/activate
```

`--system-site-packages` is fundamental to make the PyCOMPSs package available when the venv is sourced.

Add to the [`requirements.txt` file](./requirements.txt) the Python packages required by your workflow. Then, install them:

```bash
python -m pip install -r requirements.txt
```
Setups using `uv` or `conda` are also possible.

??? info "What if your cluster does not have nodes with internet connection?"
    Find the precise Python version and architecture. In the cluster, get:
    ```bash
    python --version
    uname -m
    ```

    Give the requirements and the system info, download locally (or in the machine with internet connection) the required wheels:
    ```bash
    pip download -d index \
          --only-binary=:all: \
          --platform manylinux2014_x86_64 \
          --implementation cp --python-version 3.12.1 --abi cp312 \
          dill guppy3 numpy pyyaml rocrate pytz pdb-tools
    ```
    This is an example of requirements.

    Then, move the downloaded wheels inside a directory (e.g., `index`) from the local machine to the cluster:
    ```bash
    rsync -PravzHS index cluster:/path/to/project
    ```

    Finally, on the cluster install the wheels inside a venv and specifying to `pip` where to find the pre-downloaded wheels:
    ```bash
    ssh machine
    # load python interpreter
    python -m venv .venv
    . .venv/bin/activate
    pip install --no-index --find-links=./index dill guppy3 numpy pyyaml rocrate pytz pdb-tools
    ```

### Shell environment or "Does you cluster have a setup `md/wrapper/env_setup_XXX.sh` file?"

To prepare the shell environment for a workflow submition, a file `md/wrapper/env_setup_XXX.sh`, where `XXX` is the nickname of your cluster, it sourced before anything (more details on [repository structure](#repository-structure)). In a nutshell, this bash file contains:

- setup to use `enqueue_compss`: this can be a [module load](https://ganana-eu-india.github.io/WP3-P3-workflow/installation/#4-create-a-tcl-module) or sourcing the [`compssenv` file](https://compss-doc.readthedocs.io/en/stable/Sections/03_Execution/02_Supercomputer.html#compss-environment-script)
- setup to use `gmx`: [same as above](https://manual.gromacs.org/current/install-guide/index.html#getting-access-to-gromacs-after-installation)
- configuration of various Slurm and COMPSs flags
- etc.

In the repo, [setup files are present for various clusters](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/wrapper) (Leonardo Booster, Marenostrum5 ACC, Dardel gpu, Lumi-G), however these files need to be adapted to the user own environment.
For new clusters, use the above mentioned files as templates. We suggest to test the setup on an interactive shell session before try to submit workflows.


## Usage

### Submit a workflow

Using default arguments:

```bash
make md
```

!!! info
      Every Python file inside `md/workflow` can be called by `make`, just use the script name without `.py`

Using custom arguments:

```bash
make CLUSTERNAME=leonardo NODES=4 INPUT_DIR=./data/inputs
```

Just type `make` to have more info or inspect the [`Makefile`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/Makefile).

### Remove output files

```bash
make clean
```
If you used custom keywords, you might need to specify them.

### Input directory structure
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
- `select.txt` (selection file for `pdb2gmx`)
- MD parameter files: `emin-charmm.mdp`, `nvt-charmm.mdp`, `npt-charmm.mdp`, `md-charmm.mdp`

See the [example directory](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/examples) for more info.

## Monitor workflow execution

To monitor a running workflow **locally**, use the [COMPSs Monitor Runner](./tools.md). Hence, from your local machine (_not the cluster!_):

```bash
./tools/run_compss_monitor.sh <cluster> <remote_parent_path>
./tools/run_compss_monitor.sh --stop
```

## Repository structure

!!! Info
      This part refers to the [`md`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md) directory

This repo uses a simplified approach to execute PyCOMPSs workflows. The following table summarizes the role of each file in the workflow definition and execution.
Levels represent the order of call when submitting a workflow (or, alternatively, the "distance" between the user issuing `make` and the workflow definition).

| level | file                                | description                                                                                                                           | For more info  | Target                   |
| ----- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------ |
| 0     | [`Makefile`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/Makefile)                          | Interface to easily handle workflow submission. Arguments that change often can be passed directly to `make`                          | type `make`    | Wrapper                  |
| 1     | [`md/wrapper/submit_workflow.sh`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/wrapper/submit_workflow.sh)      | Wrapper to the `enqueue_compss` program.                                                                                              | type `make`    | PyCOMPSs                 |
| 1     | [`md/wrapper/env_config_<cluster>.sh`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/wrapper) | Configuration file sourced by `submit_workflow.sh`. This bash describes the shell environment in which the workflow will be executed. | Check the file | Shell environment, Slurm |
| 2     | [`md/workflow/md.py`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/workflow/md.py)                  | Tasks and pipeline implementation. This file controls the whole workflow.                                                             | Check the file | Workflow                 |
| 3     | [`md/workflow/md-provenance.yaml`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/workflow/md-provenance.yaml)     | Configuration for Data Provenance.                                                                                                    | Check the file | Workflow                 |

In this setup, the workflow is managed through a `Makefile`.
The arguments that change often (such as input/output directories, number of cores per task, workflow name etc) are passed directly to `make` while more "stable" arguments are configured in `./wrapper`.
The main files for the workflow specification are stored inside `./wrapper/env_config_<cluster>.sh` and `./wrapper/submit_workflow.sh`.

!!! warning
      Currently, not all Slurm or COMPSs arguments are wrapped. To modify this aspect, see [how to do it](#add-more-slurm-or-compss-arguments-to-the-wrappers).

      All arguments that are not set either in `make` nor `env_config_<cluster>.sh` use the default values as expressed in the COMPSs queue config file `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`. See [COMPSs documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/03_Configuration/02_Supercomputer.html) for more info.

### Miscellaneous notes

!!! note
    These are some notes for version `3.3.3` for edge cases or non-standard behaviors.

- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths even though in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is cleaner, hence it is best practice, than defining arguments through the python function arguments. See [`md.py`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/workflow/md.py).
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs).
- the `constraint` decorator instruct the task on the OMP threads to allocate for the task, among many other things. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `gmx mdrun` you should always check the `mdp` file that starts the simulation to know which file will be produced. A common error is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to output a `trr` file but it does not appear, COMPSs will exit with an error, causing you headaches.
- COMPSs search for **checkpoints** and loads them! It avoids running the same task multiple times
  - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
  - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
  - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
  - one **unresolved issues** (as in the 3.3.3 version): in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
- `print` statements in the main code that write on the STOUT, are catched by the `.COMPSs/jobs/job-[JOBID].out` files.

## Adapt the workflow at your needs

### Adapt the workflow

Typically, one starts modifying the Python scripts in [`workflow`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/workflow) in which a high-level description of the workflow divided in tasks is detailed.
After that, one specifies the environment in which the workflow will be executed. The latter is controlled by bash scripts in [`wrapper`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/wrapper) and the [`Makefile`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/Makefile).

The procedure is usually the following:

1. **Workflow definition**: define a Python script controlling the main pipeline. The tasks involved in the workflow can be defined in the same file or in separate ones. All these are stored in [`workflow`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/workflow). The main Python file has a name that will be used to call PyCOMPSs. In this repo, tasks and pipeline are detailed inside [`md/workflow/md.py`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/blob/main/md/workflow/md.py). Hence, the name of the workflow is `md`.
2. **Setup the execution environment**: open [`md/wrapper/env_config_<cluster>.sh`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/wrapper) and customize Slurm variables, modules to load before execution and everything to prepare the shell for workflow execution. This bash is sourced before launching `enqueue_compss`, which is called in [`md/wrapper/submit_workflow.sh`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md/wrapper/submit_workflow.sh). Customize the latter to adjust `enqueue_compss` flags.

??? info "Some references to get started with PyCOMPSs"
      - [PyCOMPSs quickstart](https://compss-doc.readthedocs.io/en/stable/Sections/00_Quickstart.html#write-your-first-app)
      - [PyCOMPSs application development](https://compss-doc.readthedocs.io/en/stable/Sections/02_App_Development/02_Python.html)
      - [Example of a Lysozyme in water MD simulation setup with PyCOMPSs](https://compss-doc.readthedocs.io/en/stable/Sections/05_Sample_Applications/02_Python/05_Lysozyme_in_water.html)

### Add more Slurm or COMPSs arguments to the wrappers

Example on how to modify level `<= 1` (see [table](#repository-structure)): implement a new COMPSs argument.
Firstly, decide whether the argument has to be specified at the `Makefile` level or at the `env_config_<cluster>.sh` level. In the two cases:

`Makefile`

1. Update the `Makefile` adding the argument on top and on the wrapper call
2. Modify `submit_workflow.sh` to catch the new argument from the command line (attention to the sanity checks), add description and add it to the other variables
3. In the same file, add the argument to the `enqueue_compss` call

`env_config_<cluster>.sh`

1. Update the file in the relevant section
2. In `submit_workflow.sh`, add the argument to the `enqueue_compss` call
