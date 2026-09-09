# Quickstart Guide

- [Quickstart Guide](#quickstart-guide)
  - [1. Get the repository](#1-get-the-repository)
  - [2. Install PyCOMPSs on HPC](#2-install-pycompss-on-hpc)
      - [Dependencies](#dependencies)
      - [Manual installation](#manual-installation)
      - [Spack (experimental)](#spack-experimental)
      - [Verify](#verify)
  - [4. Set up and run the workflow](#4-set-up-and-run-the-workflow)
      - [Python environment](#python-environment)
      - [File structure](#file-structure)
      - [Submit](#submit)
      - [Clean up](#clean-up)
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

> [!NOTE]
> Full details: [PyCOMPSs installation](./PyCOMPSs.md).

#### Dependencies

Java (11+), Boost, Python (3.11+), gcc, autotools. Load via your cluster's module system.

#### Manual installation

```bash
wget https://compss.bsc.es/repo/sc/stable/COMPSs_<version>.tar.gz
tar -xvzf COMPSs_<version>.tar.gz
cd COMPSs
./install -T <targetDir> [<supercomputer.cfg>]
```

Create a TCL module file to expose `$COMPSS_HOME`, `PATH`, `CLASSPATH`, `PYTHONPATH`. See [PyCOMPSs.md](./PyCOMPSs.md) for a template.

#### Spack (experimental)

Not officially supported by COMPSs team. Requires personal Spack repo, custom `package.py` (provided in `docs/spack/`), and `COMPSS_SUPERCOMPUTER_CFG` env var. See [PyCOMPSs.md § Experimental](./PyCOMPSs.md#experimental-installation-using-spack).

#### Verify

```bash
enqueue_compss -h
```

## 4. Set up and run the workflow

> [!NOTE]
> Full details: [`workflow setup and usage`](./workflow_setup_and_usage.md).

#### Python environment

```bash
python -m venv ../envs/<venv_name> --system-site-packages
source ../envs/<venv_name>/bin/activate
pip install -r requirements.txt
```

`--system-site-packages` exposes PyCOMPSs to the venv.

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

## 5. Contribute back

> [!NOTE]
> See more info in the [contribution documentation](./contribution.md)

Made an improvement? Open a Pull Request:

```bash
git add -A
git commit -m "Describe your changes"
git push origin feat-branch-name
```

Then open a PR to the [main repository](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/pulls) and wait for review.

For bugs or feature requests, [open an issue](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/issues) using the provided templates.
