# PyCOMPSs installation

- [PyCOMPSs installation](#pycompss-installation)
  - [Installation on HPC](#installation-on-hpc)
    - [\[Recommended\] Manual installation: example on CINECA's Leonardo](#recommended-manual-installation-example-on-cinecas-leonardo)
    - [\[Experimental\] Installation using Spack](#experimental-installation-using-spack)
    - [Troubleshoot](#troubleshoot)
  - [Post-installation configuration](#post-installation-configuration)
    - [Supercomputer](#supercomputer)
    - [Queue system (scheduler)](#queue-system-scheduler)
  - [Miscellaneous notes](#miscellaneous-notes)

## Installation on HPC

This documentation guides the user on installing COMPSs, and its Python bindings PyCOMPSs, using the spack recipe.
The COMPSs documentation provides already a good overview of the process and the user is advised to read it beforehand to understand what is installed and solve possible issues.

- [Installation overview](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration.html)
- [COMPSs documentation on dependencies](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/01_Dependencies/02_Supercomputer.html)
- [COMPSs documentation on HPC installation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/02_Installation/03_Supercomputers.html).

### [Recommended] Manual installation: example on [CINECA's Leonardo](https://www.hpc.cineca.it/systems/hardware/leonardo/)

This installation follows the [official one](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration.html).

> [!NOTE]
> Please, refer to COMPSs documentation for more info and guidance on your cluster.

We assume that the user is connected to the cluster.

1. We firstly load the required dependencies. In Leonardo, using modules:
   - Java:
     ```bash
     module load openjdk/11.0.20.1_1
     ```
   - Boost:
     ```bash
     module load boost/1.85.0--openmpi--4.1.6--gcc--12.2.0
     ```
   - Python:

     ```bash
     module load python/3.11.7
     ```

     In Leonardo, you need to install `pip` and other required building tools for the user. [For example](https://pip.pypa.io/en/stable/installation/#supported-methods):

     ```bash
     python -m ensurepip --upgrade
     python -m pip install --user wheel setuptools --upgrade
     ```

   - Autotools: usually, already available. Testable with `autoconf --version`.
   - `gcc`:
     ```bash
     module load gcc/12.2.0
     ```
     For more info on gcc compilation, see the [Troubleshoot section](#troubleshoot).

2. Make sure that the following environmental variables are setup.
   1. `JAVA_HOME`: it should be setup by the `openjdk` module. You can always check with `echo $JAVA_HOME`.
   2. `BOOST_CPPFLAGS`: One has to check the one used for the compilation of the `boost` library. On Leonardo, after loading the module, we can inspect `$BOOST_HOME/.spack/spack-build-out.txt`, and found that:

      ```bash
      export BOOST_CPPFLAGS="-std=c++11 -pthread -O2 -s"
      ```

      which are the default flags of the B2 building system for that version.

3. From the [download page](https://compss.bsc.es/repo/sc/stable/) select the COMPSs version. Then:

   ```bash
   wget https://compss.bsc.es/repo/sc/stable/COMPSs_<version>.tar.gz
   tar -xvzf COMPSs_<version>.tar.gz
   cd COMPSs
   ./install -T <targetDir> [<supercomputer.cfg>]
   ```

   Note that `supercomputer.cfg` refers to the config file used for that HPC and Scheduler (more info on the [Configuration section](#infrastructure-configuration), example files can be found in `COMPSs/Runtime/scripts/queues/supercomputers`). `<targetDir>` is where to install COMPSs, be aware that the content of that directory will be erased. `-T` exclude the tracing system, however it can be included if the supercomputer supports `extrae` (for more info see the [official documentation](https://compss-doc.readthedocs.io/en/stable/Sections/04_Ecosystem/03_Tracing/01_Apps_tracing.html)). More info on the available flags with `./install --help`.

   A correct installation prints to the stdout the successfull installation of COMPSs and all its bindings.

4. To make binaries available and set the right environmental variables in the shell, one can create a [tcl module](https://modules.readthedocs.io/en/latest/index.html):

   ```bash
   touch <path/to/modules>/compss/<version>
   ```

   A minimal example is the following:

   ```tcl
   #%Module

   set COMPSS_HOME "<targetDir>"
   prepend-path PATH "${COMPSS_HOME}/Runtime/scripts/user:${COMPSS_HOME}/Runtime/scripts/utils"
   prepend-path CLASSPATH "${COMPSS_HOME}/Runtime/compss-engine.jar"
   prepend-path PATH "${COMPSS_HOME}/Bindings/c/bin"
   prepend-path PYTHONPATH "${COMPSS_HOME}/Bindings/python/
   export R_LIBS_USER=${COMPSS_HOME}/Bindings/RCOMPSs/user_libs/:$R_LIBS_USER

   setenv COMPSS_HOME $COMPSS_HOME

   prereq python/3.11.7
   prereq openjdk/11.0.20.1_1
   ```

   `R_LIBS_USER` is used in case of R bindings installation.

   and save it in `<path/to/modules>/compss/[version]`. Then it can be loaded using:

   ```bash
   module use --append <path/to/modules> # that can be added in ~/.bashrc or before a workflow run
   module load compss/[version]
   ```

To test out the installation, after loading the module, run:

```bash
enqueue_compss -h
```

### [Experimental] Installation using Spack

> [!WARNING]
> This installation is experimental and not directly supported by the COMPSs' Team. If issues arises, please refer to the officially supported [manual installation](#example-of-manual-installation-on-cinecas-leonardo)

> Some reference if you are not used to Spack:
>
> - [Add a package to Spack](https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html#package-creation-tutorial)
> - [Advance packaging tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html)
> - Reference files in directory [spack](./spack/)

> [!NOTE]
> This repository contains two `package.py` depending on the Spack version. `0_22/compss/package.py` has been tested with Spack `<= 0.22.x`. `1_00/compss/package.py` has been tested with Spack `1.0 > <= 1.2`.

> [!NOTE]
> If you encounter any issues in the process, read the [troubleshooting section](#troubleshoot) before open an issue.

These steps assume that Spack is available in your shell. It might be loaded in your HPC environment, for example using `module load spack`.

If you already have a Spack custom repo (in this example, the namespace is called `<repo name>`), skip to step 2, otherwise start from 1 creating a custom repo [^2].

1. Create a personal repo:
   ```bash
   spack repo create path/to/root/repos <repo name>
   spack repo add path/to/root/repos/<repo name>
   ```
   This will create a new repository, and a namespace, where to add recipes for softwares called `<repo name>`.
2. Add COMPSs to the repo:
   ```bash
   spack create --name compss -N <repo name>
   ```
   Then you will be prompt with the default editor to update the `package.py` of COMPSs that you can close.
   Overwrite the content of `spack edit compss` with the `package.py` of this repo:
   ```bash
   cp <this repo>/docs/spack/<spack_version>/compss/package.py path/to/root/repos/<repo name>/packages/compss/
   ```
3. Concretize the spec and, finally, install COMPSs specifying the `cfg` through the environmental variable `COMPSS_SUPERCOMPUTER_CFG` (only the file name), for example:
   ```bash
   spack spec -Il compss
   ```
   ```bash
   COMPSS_SUPERCOMPUTER_CFG=leonardo.cfg spack install compss
   ```
4. To load environmental variables and add binaries to `PATH` at convenience, generate the module with:
   ```
   spack module tcl refresh -y
   ```

Now, you can load, in the current shell, COMPSs using:

```
module load compss
```

which full name is something like `compss/3.3.3--gcc--12.2.0`. _Alternatively_, you can directly use:

```
spack load compss
```

To test the installation just type `enqueue_compss --version`.

[^2]: Custom repos are required because most probably you won't have the permission to add software to the main repo of your cluster

### Troubleshoot

<details>
<summary>The user cannot create a personal repo in the cluster</summary>

If this operation results in permission errors in your cluster, probably the user is not allowed to have a personal `repo.yaml` file.
In this case, contact your system administrator. A possible solution could be [re-enable the user to perform such operation](https://spack.readthedocs.io/en/latest/configuration.html#overriding-local-configuration) specifying `unset SPACK_DISABLE_LOCAL_CONFIG`

</details>

<details>
<summary>COMPSs cannot be found when creating the Spack spec</summary>

In a cluster, is customary to have a system Spack repository called `builtin`. This can be checked using:

```bash
$ spack repo list
[+] builtin     v2.2    /path/to/builtin
[+] <repo name>    v2.4    /path/to/<repo name>
```

If `builtin` is higher than you personal `<repo name>`, as in the above output, Spack might not find `compss` because it searches for it in `builtins`. To solve this, you can specify the namespace from which the package should be installed:

```bash
spack spec -Il <repo name>.compss
```

and similarly when installing it.

</details>

<details>
<summary>Errors while compiling COMPSs with gcc 13 or later</summary>

There are two possibilities. You can unsure that the C compilation is compliant with the COMPSs code by specifying the environmental variable `export CFLAGS="-std=gnu17"` before installing COMPSs. This is an easy fix with recent `gcc` versions. You might need to modify the spack recipe in case the variable is not correctly used.

On the other side, one can use `gcc` 12 by specifying to spack to use it. To ensure this you can specify a [compilation preference](https://spack.readthedocs.io/en/latest/frequently_asked_questions.html#specific-compiler-for-all-packages) (for transitive dependencies, because COMPSs does not depend on `gcc` directly). On Spack 1.0 or later, find Spack's `package.yaml` with:

```bash
spack config edit packages
```

and add:

```bash
packages:
  c:
    prefer:
    - gcc@12
  cxx:
    prefer:
    - gcc@12
```

</details>

<details>
<summary>Cannot install PyCOMPSs because no `pip` available</summary>

In this case, you need to install `pip` within the Python interpreter that you use to install PyCOMPSs and run workflows. Follow the [official documentation](https://pip.pypa.io/en/stable/installation/) for this.

Be aware that if you install `pip` and PyCOMPSs within a `venv`, PyCOMPSs will be installed **only** on that virtual environment. Therefore, you will need to always source it to run a workflow. We discourage the latter approach.

</details>

<details>
<summary>No module compss when using module load</summary>

If you cannot find the `compss` module, you need to issue first (or append to your shell config file, e.g. `~/.bashrc`, to make it permanent) `module use --append $SPACK_HOME/modules/` or the location where Spack creates modules.

</details>

<details>
<summary>enqueue_compss runs but it cannot find other binaries</summary>

If binaries like `enqueue_compss` or related are in the `PATH` variable, but do not work when invoked, inspect the module file generated with `ml show compss`. A common problem is an incorrect `COMPSS_HOME` environmental variable.

To fix this, you need to modify accordingly to the error the `package.py` file in the `env.set("COMPSS_HOME", compss_home)` line.

</details>

## Post-installation configuration

COMPSs uses [configuration files to adapt to different clusters](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/03_Configuration/02_Supercomputer.html). The general structure is the following:
![compss configs](https://compss-doc.readthedocs.io/en/stable/_images/queue_scripts_structure.png)
where `sc.cfg` is the supercomputer config file and `queue_system.cfg` is the confif file for the job scheduler.

### Supercomputer

This file is selected during [installation](#installation-on-hpc) when calling `./install` or with the env var `COMPSS_SUPERCOMPUTER_CFG`. Afterward, it is renamed as `default.cfg` in the COMPSs installation directory (`<targetDir>Runtime/scripts/queues/supercomputers/default.cfg` or `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`), where config files for other clusters are.

Supercomputers `cfg` files contains a set of variables to indicate the queue system used by a supercomputer, paths where the shared disk is mounted, etc.
These files are provided with the COMPSs installation, already tuned for different supercomputers by the BSC team.
We suggest taking a look at them to have an idea of the default parameters. If not specified in the `enqueue_compss` flags, the `default.cfg` one is picked.

For reproducibility, in this repo the `cfg` files stored in [`supercomputer_configs`](./supercomputer_configs/) are tested to work with the implementation of the [`md`](./../md/) workflow.

### Queue system (scheduler)

The `cfg` files contain a set of variables which are used by the other scripts. On one hand, the queue system `cfg`s contain variables to indicate the commands used by the system to submit and spawn processes, the commands or variables to get the allocated nodes and the directives to indicate the number of nodes, processes, etc.
These are container in `$COMPSS_HOME/Runtime/scripts/queues/queue_systems/`.

_The user is advice to not change them_.

## Miscellaneous notes

> [!NOTE]
> These are some notes for version 3.3.3 for edge cases or non-standard behaviors.

- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths even though in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is cleaner, hence it is best practice, than defining arguments through the python function arguments. See [`md.py`](../md/workflow/md.py).
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs).
- the `constraint` decorator instruct the task on the OMP threads to allocate for the task, among many other things. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `gmx mdrun` you should always check the `mdp` file that starts the simulation to know which file will be produced. A common error is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to output a `trr` file but it does not appear, COMPSs will exit with an error, causing you headaches.
- COMPSs search for **checkpoints** and loads them! It avoids running the same task multiple times
  - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
  - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
  - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
  - one **unresolved issues** (as in the 3.3.3 version): in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
- `print` statements in the main code that write on the STOUT, are catched by the `.COMPSs/jobs/job-[JOBID].out` files.
