# Quickstart Guide

This workflow uses [PyCOMPSs](https://www.bsc.es/research-and-development/software-and-apps/software-list/comp-superscalar/) as Workflow Managment System and [GROMACS](https://www.gromacs.org/) with [PMX](https://degrootlab.github.io/pmx/) for MD and Free Energy evaluations.

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

!!! info
    Full details in [PyCOMPSs installation section](./installation.md).

#### Dependencies

Java (11+), Boost, Python (3.11+), gcc, autotools. Load via your cluster's module system.

#### Manual installation

```bash
wget https://compss.bsc.es/repo/sc/stable/COMPSs_<version>.tar.gz
tar -xvzf COMPSs_<version>.tar.gz
cd COMPSs
./install -T <targetDir> [<supercomputer.cfg>]
```

Create a TCL module file to expose `$COMPSS_HOME`, `PATH`, `CLASSPATH`, `PYTHONPATH`. See [PyCOMPSs.md](./installation.md) for a template.

#### Verify

```bash
enqueue_compss -h
```

## 3. Set up and run the workflow

!!! info
    Full details: [`workflow setup and usage`](./workflow_setup_and_usage.md).

#### Python environment

```bash
python -m venv ../envs/<venv_name> --system-site-packages
source ../envs/<venv_name>/bin/activate
pip install -r requirements.txt
```

`--system-site-packages` exposes PyCOMPSs to the venv.

#### Gromacs

The user is responsible to install Gromacs in the machine. Please refer to the [official installation guide](https://manual.gromacs.org/current/install-guide/index.html) or [an example for the Leonardo cluster](./installation.md).

#### File structure

| File                              | Purpose                                 | When to edit                       |
| --------------------------------- | --------------------------------------- | ---------------------------------- |
| `Makefile`                        | Entry point, default arguments          | Change workflow execution defaults |
| `workflow/md.py`                  | Task definitions, pipeline logic        | Adapt workflow steps               |
| `wrapper/env_config_<cluster>.sh` | Cluster modules, `enqueue_compss` flags | New cluster or queue settings      |
| `wrapper/submit_workflow.sh`      | Submission wrapper to `enqueue_compss`  | Rarely                             |

#### Submit

```bash
make                                # list targets
make md                             # default run
make CLUSTERNAME=dardel NODES=4     # override defaults
```

Outputs and `.COMPSs/` runtime logs appear in the workflow directory.

#### Clean up

```bash
make clean
```

## 4. Contribute back

!!! info
    See more info in the [contribution documentation](./contributing.md)

Made an improvement? Open a Pull Request:

```bash
git add -A
git commit -m "Describe your changes"
git push origin feat-branch-name
```

Then open a PR to the [main repository](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/pulls) and wait for review.

For bugs or feature requests, [open an issue](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/issues) using the provided templates.
