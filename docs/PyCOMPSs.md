## Installation on HPC

References:
- [COMPSs documentation for installing on HPC](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/04_Supercomputers.html).
- [COMPSs documentation on dependencies](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/01_Dependencies.html)


### Installation example on [CINECA's Leonardo](https://www.hpc.cineca.it/systems/hardware/leonardo/)

1. Dependencies: through spack, we load the [necessary dependancies](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation/04_Supercomputers.html).
    1. Java:
        ```bash
        module load openjdk/11.0.20.1_1
        ```
    2. Boost:
        ```bash
        module load boost/1.83.0--openmpi--4.1.6--gcc--12.2.0
        ```
    3. Autotools: they should be already available (I tested various spack installations, use the one already loaded to avoid problems)
2. Make sure that the following environmental variables are setup (this is what I have):
    ```bash
    export JAVA_HOME=/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/openjdk-11.0.20.1_1-az5t54alcubudjbebkvu7uqusjd2sawj
    ```
    While for the CPP flags, one has to check the one used for the compilation of the boost library. In my case, I inspected the spack specifications in the compilation, that can be found in `/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-12.2.0/boost-1.83.0-ti6wkhbw4ddu6xbsaecjticlmxa3ihfw/.spack/spack-build-out.txt`, and found that:
    ```bash
    export BOOST_CPPFLAGS="-std=c++11 -O2 -s"
    ```
3. Perform installation by downloading precompiled binaries (**check the latest version!**):
    ```bash
    wget https://compss.bsc.es/repo/sc/stable/COMPSs_3.3.3.tar.gz
    tar -xvzf COMPSs_3.3.3.tar.gz
    # Install COMPSs at your preferred target location
    mkdir COMPSs_3.3.3_installation # create a separated dir for installation
    cd COMPSs
    ```
    1. Setup a Python environment for the Python bindings (see [here](https://github.com/bsc-wdc/compss/blob/stable/compss/programming_model/bindings/python/pyproject.toml) to check out the dependencies because they are not explicitated):
        ```bash
        ml python/3.11.6--gcc--8.5.0
        python -m venv compss_py_bindings
        source compss_py_bindings/bin/activate
        python -m pip install "setuptool>=69.1.0" wheel
        ```

    Now complete the installation, having the python environment still active: 
    ```bash
    ./install $PUBLIC/compss/COMPSs_3.3.3_default_installation $PUBLIC/compss/COMPSs/Runtime/scripts/queues/supercomputers/leonardo.cfg
    ```
    Note, the config files was provided in the public repo of the project. For custom cfg files for a different HPC you need to confront with the sysadmin and BSC.
    Note: C-bindings are essential for the Python bindings, cause the latter is built on top of the former. We are avoiding only the tracing routines, despite useful they add another layer of compleicatin in the compilation and installation.


### Usage
I've created a Module to source the relevant environmental variables, that can be accessed loading:
```bash
ml /leonardo/pub/userinternal/lsalicar/modules/compss/3.3.3
```
Now, applications such as `runcompss -v` and `enqueue_compss -h` should be reachable.

I've setup a python venv to install `pyyaml` and `rocrate` that are necessary to create the YAML for the Ro-Crate format. Hence I've created a venv inside `my_first_pycomps` dir with:
```bash
python -m venv venv --system-site-packages
```
activate it and installed `pyyaml` and `rocrate` ans `pytz`.

## Miscellaneous notes

- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths eventhough in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is much more cleaner than defining arguments through the python function arguments.
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs).
- the `contraint` decorator instruct the task on the OMP threads to allocate for the task. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `mdrun` you should always check the `mdp` file that starts the simulation to know which file will be produced. A common error is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to output a `trr` file but it does not appear, COMPSs will exit with an error, causing you headaches.
- To use the **monitor**, please refer to [this very hidden part of the documentation](https://compss-doc.readthedocs.io/en/3.3.3/Sections/03_Execution_Environments/03_Deployments/01_Master_worker/02_Supercomputers/05_COMPSs_monitor.html)
- COMPSs search for **checkpoints** and loads them! It avoids running the same task multiple times
   - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
   - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
   - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
   - one **unresolved issues** (as in the 3.3.3 version): in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
- `print` statements in the main code that write on the STOUT, are catched by the `job-[JOBID].out` files.
