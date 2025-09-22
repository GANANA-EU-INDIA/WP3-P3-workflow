# MD simulation with Gromacs

This repo tries to setup a MD simulations of a simple sistem, a protein in water environment, using GROMACS.
The idea is to test COMPSs and its features. In particular:
- defining the workflow
- ease in run it through Slurm (using alla available resourses)
- ease in monitor it
- a test case with a failing task (artificially induced, slurm allocates too little time for MD simulation)
- provenance and sharing of the workflow

Based on the official [GROMCAS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html), [zenodo link](https://zenodo.org/records/14803238).


## Installation

## Usage

### Preparation
On Leonardo, install compss and load it through the `module` command. If you have a COMPSs installation, a modulefile initializing it and added the path to the modules to the `MODULEPATH` varibale, then you can load COMPSs as:
```bash
ml compss
```

<details>
<summary>Personal module file</summary>

```tcl
#%Module

module-whatis "COMP Superscalar (COMPSs)/pyCOMPSs is a task-based programming model which aims to ease the development of applications for distributed infrastructures, such as large High-Performance clusters (HPC), clouds and container managed clusters. COMPSs provides a programming interface for the development of the applications and a runtime system that exploits the inherent parallelism of applications at execution time."


proc ModulesHelp { } {
   puts stderr "Loads (py)COMPSs 3.3.3"
}

set COMPSS_HOME "/leonardo/pub/userinternal/lsalicar/compss/COMPSs_3.3.3_default_installation/"
prepend-path PATH "${COMPSS_HOME}/Runtime/scripts/user:${COMPSS_HOME}/Runtime/scripts/utils:${COMPSS_HOME}/CLI"
prepend-path CLASSPATH "${COMPSS_HOME}/Runtime/compss-engine.jar"
prepend-path PATH "${COMPSS_HOME}/Bindings/c/bin"
prepend-path PYTHONPATH "${COMPSS_HOME}/Bindings/python/:${COMPSS_HOME}/cli/lib/python3.6/site-packages/"

setenv COMPSS_HOME $COMPSS_HOME

prereq python
prereq openjdk/11.0.20.1_1
```

</details>

Afterwards, we need a python environment with all requirement satisfied. One can use the `requirement.txt` file in the work flow directory to setup the environment.


### How to call the workflow

1. modify hardcoded file paths inside `enqueue_submit.sh`, especially `MASTER_DIR` and the subsequents at necessity.


## Notes

- Read notes on the `.sh` to know niche things regarding calling the `enqueue_compss` binary
- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths eventhough in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is much more cleaner than defining arguments through the python function arguments.
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs, see mail frmo Conejero). This is the approach used in the `plain_compss` example.
- the `contraint` decorator instruct the task on the OMP threads to allocate for the task. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `mdrun` you should always check the `mdp` file that stat the simulation to know which file will be produced. An error I stumble upon is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to have a `trr` file but didn't get it, COMPSs will exit with an error, causing you headaches.
- To use the **monitor**, pls refer to [this very hidden part of the documentation](https://compss-doc.readthedocs.io/en/3.3.3/Sections/03_Execution_Environments/03_Deployments/01_Master_worker/02_Supercomputers/05_COMPSs_monitor.html)
- COMPSs search for checkpoints and loads them! It avoids running the same task multiple times
   - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
   - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
   - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
   - one **unresolved issues**: in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
   - another **unresolved issues**: if the first run fails at some point (let's say, before the production phase), the second run (with the workflow corrected) corretly identifies the already done steps and jump directly into the missing ones. However, I get an error from `gmx` that tries to use `npt.tpr` for the production phase instead of `prod_npt.tpr` (obv, the workflow uses correctly the latter and the `grompp` phase is perform to create the `prod_npt.tpr`)
   ![example of two identical runs, one ofter the other performing all calculation up until prod](./assets/graphs_1st_2nd_aftercheckpoint.png)
- `print` statements in the main code that write on the STOUT, are catched by the `compss-[runid].out` file

## Logbook
- The original example from GROMACS contains a PDB that, when preprocessed with `pdb2gmx`, generates two additional files (`*.itp`, complementary files to the topology that are produces one for each chain) that I don't know how to specify COMPSs that they are produces, nor to instruct `gmx` to avoid them and place everything inside the topology file. Hence, instead of using `1fjs` we try the one exploited in the COMPSs doc: `1aki`.
- After meeting with Javier (25/8/25): the issue is the ability for compss to read a partially run workflow (that used checkpoints, see `check` branch) to continue it or finish it. The problem we discovered is that workers are not instructed to execute anything (worker seems fine, runtime seems not) and this seems to be caused by the runtime not able to load and check data relationships. Practically, file that are not needed for the continuation, the topology file, and that should be read-only, are checked and _written_. This is weird.