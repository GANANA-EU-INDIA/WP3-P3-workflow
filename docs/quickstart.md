# Quickstart Guide

- [Quickstart Guide](#quickstart-guide)
  - [1. Get the repository](#1-get-the-repository)
  - [2. Install PyCOMPSs on HPC](#2-install-pycompss-on-hpc)
  - [4. Set up and run the workflow](#4-set-up-and-run-the-workflow)
  - [5. Contribute back](#5-contribute-back)


## 1. Get the repository

Clone this repository where you want to use it:

```bash
git clone https://github.com/GANANA-EU-INDIA/WP3-P3-workflow.git
cd WP3-P3-workflow
```

Optionally, create a branch to keep the original workflow intact and allow future updates via `git pull`:

```bash
git switch -c new-branch-name
```

## 2. Install PyCOMPSs on HPC

The recommended method is via **Spack**. Make sure Spack is available in your shell (e.g. `module load spack`).

**Step 1 — Create a personal Spack repo** (skip if you already have one):

```bash
spack repo create path/to/root/repos <repo-name>
spack repo add path/to/root/repos/<repo-name>
```

**Step 2 — Add COMPSs to the repo:**

```bash
spack create --name compss -N <repo-name>
cp <this-repo>/docs/spack/<spack_version>/compss/package.py \
   path/to/root/repos/<repo-name>/packages/compss/
```

> Two `package.py` variants are provided: `0_22/` for Spack `<= 0.22.x` and `1_00/` for Spack `1.0–1.2`.

**Step 3 — Install**, specifying the supercomputer config:

```bash
spack spec -Il compss
COMPSS_SUPERCOMPUTER_CFG=leonardo.cfg spack install compss
```

**Step 4 — Generate and load the module:**

```bash
spack module tcl refresh -y
module load compss
```

Verify the installation:

```bash
enqueue_compss --version
```

More post-installation configurations and troubleshoots can be found in [PyCOMPSs installation documentation](./PyCOMPSs.md).


## 4. Set up and run the workflow

**Python environment** — create a Python environment for your workflow:

```bash
python -m venv ../envs/<venv_name> --system-site-packages
. ../envs/<venv_name>/bin/activate
pip install -r requirements.txt
```

The `--system-site-packages` flag is required to expose the PyCOMPSs package inside the venv.

**Adapt the workflow** — Inside the workflow directory (e.g.`md`), these files control the workflow execution:

- `workflow/md.py` — tasks and pipeline logic. This is the main file to modify when changing the workflow.
- `wrapper/env_config_<cluster>.sh` — Slurm, PyCOMPSs `enqueue_compss` arguments, and modules to load before execution.
- `wrapper/submit_workflow.sh` — wraps `enqueue_compss`.
- `Makefile` — main file to trigger workflow submission. Contains some workflow arguments.

These are the one to modify.

**Submit**:

```bash
make                                # list available targets and arguments
make <workflow-name>                # default arguments
make CLUSTERNAME=dardel NODES=4     # override specific arguments
```

**Clean up** produced files:

```bash
make clean
```

For a full description of the repository structure and how to wrap additional Slurm/COMPSs arguments, see [`workflow setup and usage`](./workflow_setup_and_usage.md).

## 5. Contribute back

Made an improvement? Open a Pull Request:

```bash
git add *
git commit -m "Describe your changes"
git push origin feat-branch-name
```

Then open a PR to the [main repository](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/pulls) and wait for review.

For bugs or feature requests, [open an issue](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/issues) using the provided templates.

See more info in the [contribution documentation](./contribution.md)
