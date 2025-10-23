- [Installation on HPC](#installation-on-hpc)
    - [Manual installation](#manual-installation)
    - [Installation on CINECA's Leonardo](#installation-on-cinecas-leonardo)
    - [Installation through Spack](#installation-through-spack)
- [Infrastructure configuration](#infrastructure-configuration)
    - [Queue system (scheduler)](#queue-system-scheduler)
    - [Supercomputer](#supercomputer)
- [Usage](#usage)
    - [Miscellaneous notes](#miscellaneous-notes)


## Installation on HPC

References:
- [COMPSs documentation for installing on HPC](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/04_Supercomputers.html).
- [COMPSs documentation on dependencies](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/01_Dependencies.html)

### Manual installation

The bird's-eye view of the installation steps is the following:
1. Satisfy dependencies and environmental variables
2. Download binaries and install them (use the included bash script to select the appropiate destination directory)
3. Make COMPSs available in the CLI (thourgh, for example, modules)
4. [Configure](#infrastructure-configuration) COMPSs to work in the cluster

You can refer to [COMPSs official documentation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/04_Supercomputers.html) for a generic step-by-step guide to install COMPSs, that has to be adapted for the HPC in use.
Here examples for some clusters are provided together with some insights.
A convinient installation using Spack is also provided.

### Installation on [CINECA's Leonardo](https://www.hpc.cineca.it/systems/hardware/leonardo/)

> [!NOTE]
> Last tested on 2025/10/20

We assume to be connected to the cluster.

1. We firstly load dependencies using modules:
    - Java:
        ```bash
        module load openjdk/11.0.20.1_1
        ```
    - Boost:
        ```bash
        module load boost/1.83.0--openmpi--4.1.6--gcc--12.2.0
        ```
    - Python:
        ```bash
        module load python/3.11.7
        ```
    - Autotools: already available on first login
2. Make sure that the following environmental variables are setup.
    1.  `JAVA_HOME` is setupped once the `openjdk` module is loaded (you can always check with `echo $JAVA_HOME`).
    2.  `BOOST_CPPFLAGS`: One has to check the one used for the compilation of the `boost` library in use. On Leonardo, after loading the module, we can inspect `$BOOST_HOME/.spack/spack-build-out.txt`, and found that:
    ```bash
    export BOOST_CPPFLAGS="-std=c++11 -pthread -O2 -s"
    ```
    which are the default flags of the B2 building system for that version.
3. From the [download page] select the last COMPSs version (`trunk` refers to the `git-main`). Than, execute:
    ```bash
    wget https://compss.bsc.es/repo/sc/stable/COMPSs_3.3.3.tar.gz
    tar -xvzf COMPSs_3.3.3.tar.gz
    cd COMPSs
    ./install ./install [options] <targetDir> [<supercomputer.cfg>]
    ```
    Note that `supercomputer.cfg` refers to the config file used for that HPC and Scheduler (more info on the [Configuration section](#infrastructure-configuration), example files can be found in `COMPSs/Runtime/scripts/queues/supercomputers`).
4. To make binaries available in the shell one can create a module. A minimal example is the following:
    ```bash
    #%Module

    set COMPSS_HOME "path/to/targetDir"
    prepend-path PATH "${COMPSS_HOME}/Runtime/scripts/user:${COMPSS_HOME}/Runtime/scripts/utils:${COMPSS_HOME}/CLI"
    prepend-path CLASSPATH "${COMPSS_HOME}/Runtime/compss-engine.jar"
    prepend-path PATH "${COMPSS_HOME}/Bindings/c/bin"
    prepend-path PYTHONPATH "${COMPSS_HOME}/Bindings/python/:${COMPSS_HOME}/cli/lib/python3.6/site-packages/"

    setenv COMPSS_HOME $COMPSS_HOME

    prereq python
    prereq openjdk/11.0.20.1_1
    ```
    and save it in `path/to/modules/COMPSs/[version]`. Then it can be loaded using:
    ```bash
    module use --append path/to/modules # that can be added in ~/.bashrc
    module load COMPSs/[version]
    ```

To test out the installation, run `enqueue_compss -h`.


### Installation through Spack

> [!NOTE]
> Tested with Spack `<= 0.22.x` on Leonardo

References:
- [Add a package to Spack](https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html#package-creation-tutorial)
- [Advance packaging tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html)
- Reference files in directory [spack](./spack/)

These steps assume that Spack binary is available in the shell. It might be loaded in a HPC environment, for example using `module load spack`.
If you already have a Spack custom repo (in this example, the namespace is called `workflow`), skip to 2, otherwise create a custom repo (this is required because most probably you won't have the permission to add software to the main repo of the cluster).
1. Create a repo:
    ```bash
    spack repo create path/to/root/.../repos workflow
    spack repo add path/to/root/.../repos/workflow
    ```
    This will create a new repository, and a namespace, where to add recipies for softwares called `workflow`.
2. Add COMPSs to the repo:
    ```bash
    spack create --name compss -N workflow
    ```
    Then you will be prompt with the default editor to update the `package.py` of COMPSs that you can close.
    Overwrite the content of `spack edit compss` with `.spack/compss/package.py` of this repo:
    ```bash
    cp -r workflow/docs/spack/compss/package $SPACK_HOME/repos/workflow/compss/
    ```
3. Create the spec: `spack spec -Il compss`. Finally, install COMPSs specifying the `cfg` through the environmental variable `COMPSS_SUPERCOMPUTER_CFG` (only the file name):
    ```bash
    COMPSS_SUPERCOMPUTER_CFG=leonardo.cfg spack install compss
    ```
4. To load environmental variables and add binaries to `PATH` at convenience, generate the module with:
    ```
    spack module tcl refresh -y
    ```
    Then you can load COMPSs binaries using:
    ```
    ml compss
    ```
    which full name is something like `compss/3.3.3--gcc--12.2.0`. Alternatively, you can directly use:
    ```
    spack load compss
    ```

To test the installation just type `enqueue_compss --version`.

> [!NOTE]
> If you cannot find the `compss` module, you need to add to your `~/.bashrc` the line `module use --append $SPACK_HOME/modules/`.

> [!NOTE]
> If binaries are available, because they path appear in the `PATH` variable, but they do not work, inspect the module file generated with `ml show compss`. A common problem is the correct set of the `COMPSS_HOME` environmental variable.


## [Infrastructure configuration](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/04_Supercomputers.html#configuration)

### Queue system (scheduler)

The cfg files contain a set of bash variables which are used by the other scripts. On the one hand, the queue system cfgs contain the variables to indicate the commands used by the system to submit and spawn processes, the commands or variables to get the allocated nodes and the directives to indicate the number of nodes, processes, etc.
These are container in `$COMPSS_HOME/Runtime/scripts/queues/queue_systems/`.

Most probably, these config files should have already all necessary variable set and *the user is not required to change them*.

### Supercomputer

On the other hand, the supercomputers cfg files contains a set of variables to indicate the queue system used by a supercomputer, paths where the shared disk is mounted.
These files are contained in `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/`.

Let's make the example oyu run on Leonardo. you can rename the cfg file for Leonardo (multiple HPCs are distributed with COMPSs) as `default.cfg` and COMPSs will use it by default.
At the top of the supercomputer file, you can set the queue system, for example Slurm, that uses the queue system cfg file, indeed the `slurm.cfg`.

If your cluster is already present, there is a good chance that the cfg file has been already tested on the infrastructure. Otherwise, the user might customized it to fit its needs.


## Usage

### Miscellaneous notes

- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths eventhough in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is cleaner, hence it is best practive, than defining arguments through the python function arguments.
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs).
- the `contraint` decorator instruct the task on the OMP threads to allocate for the task, among many other things. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `gmx mdrun` you should always check the `mdp` file that starts the simulation to know which file will be produced. A common error is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to output a `trr` file but it does not appear, COMPSs will exit with an error, causing you headaches.
- To use the **monitor**, please refer to [this part of the documentation](https://compss-doc.readthedocs.io/en/3.3.3/Sections/03_Execution_Environments/03_Deployments/01_Master_worker/02_Supercomputers/05_COMPSs_monitor.html)
- COMPSs search for **checkpoints** and loads them! It avoids running the same task multiple times
   - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
   - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
   - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
   - one **unresolved issues** (as in the 3.3.3 version): in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
- `print` statements in the main code that write on the STOUT, are catched by the `.COMPSs/jobs/job-[JOBID].out` files.
