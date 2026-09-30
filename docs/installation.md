## PyCOMPSs

### Installation on HPC

This documentation guides the user on installing COMPSs, and its Python bindings PyCOMPSs.
The COMPSs documentation provides already a good overview of the process and the user is advised to read it beforehand to understand what is installed.

??? info "PyCOMPSs documentation links"
    - [Installation overview](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration.html)
    - [COMPSs documentation on dependencies](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/01_Dependencies/02_Supercomputer.html)
    - [COMPSs documentation on HPC installation](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/02_Installation/03_Supercomputers.html).

#### **[Recommended]** Manual installation: example

This installation follows the [official one](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration.html). It shows the main passages as done in the [CINECA's cluster Leonardo](https://www.hpc.cineca.it/systems/hardware/leonardo/).

!!! warning
    Please, refer to COMPSs documentation for more info and guidance on your cluster.

We assume that the user is connected to the cluster.

##### 1: Load dependencies

Load the required dependencies. In Leonardo, using modules:

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

- Autotools: usually already available. Testable with `autoconf --version`.

- gcc:

    ```bash
    module load gcc/12.2.0
    ```

    For more info on gcc compilation, see the [Troubleshoot section](#troubleshoot).

##### 2: Setup environment variables

Make sure the following environment variables are set:

- `JAVA_HOME`: should be set by the `openjdk` module. Check with `echo $JAVA_HOME`.

- `BOOST_CPPFLAGS`: check the one used for the `boost` library compilation. On Leonardo, inspect `$BOOST_HOME/.spack/spack-build-out.txt`:

    ```bash
    export BOOST_CPPFLAGS="-std=c++11 -pthread -O2 -s"
    ```

    These are the default flags of the B2 building system for that version.

##### 3: Download and install COMPSs

From the [download page](https://compss.bsc.es/repo/sc/stable/) select the COMPSs version:

```bash
wget https://compss.bsc.es/repo/sc/stable/COMPSs_<version>.tar.gz
tar -xvzf COMPSs_<version>.tar.gz
cd COMPSs
./install -T <targetDir> [<supercomputer.cfg>]
```

Note that `supercomputer.cfg` refers to the config file used for that HPC and Scheduler (more info on the [Configuration section](#post-installation-configuration), example files can be found in `COMPSs/Runtime/scripts/queues/supercomputers`). `<targetDir>` is where to install COMPSs, be aware that the content of that directory will be erased. `-T` excludes the tracing system, however it can be included if the supercomputer supports `extrae` (for more info see the [official documentation](https://compss-doc.readthedocs.io/en/stable/Sections/04_Ecosystem/03_Tracing/01_Apps_tracing.html)). More info on the available flags with `./install --help`.

A correct installation prints the successful installation of COMPSs and all its bindings to stdout.

##### 4: Create a (tcl) module

To make binaries available and set the right environment variables in the shell, create a [tcl module](https://modules.readthedocs.io/en/latest/index.html):

  ```bash
  touch <path/to/modules>/compss/<version>
  ```

A minimal example:

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

Save it in `<path/to/modules>/compss/[version]` and load it using:

   ```bash
   module use --append <path/to/modules> # that can be added in ~/.bashrc or before a workflow run
   module load compss/[version]
   ```

To test out the installation, after loading the module, run:

```bash
enqueue_compss -h
```

#### Dardel Installation

We use a custom Java 21 JRE installation because of dependencies mismatch with the OpenJDK available in Dardel. Hence, we use the Oracle JRE LTS 21:

```bash
cd # perform operation in the user home
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz
tar -xvf jdk-21_linux-x64_bin.tar.gz
rm jdk-21_linux-x64_bin.tar.gz
```

The relative **lua** module saved in `<pathToModules>/modules/java/21.lua` is:

```lua
-- -*- lua -*-
-- Module: jdk
-- -- Sets up Java 21 (JDK 21.0.12.1)

help([[
This module sets up the Java Development Kit (JDK) 21.0.12.1.

It sets JAVA_HOME and adds $JAVA_HOME/bin to PATH.
]])

whatis("Name: JDK")
whatis("Version: 21.0.12.1")
whatis("Description: Java Development Kit")
whatis("Sets JAVA_HOME and prepends $JAVA_HOME/bin to PATH")

local HOME = "<userHomePathAbsolute>/jdk-21.0.12.1"

setenv("JAVA_HOME", HOME)
prepend_path("PATH", pathJoin(HOME, "bin"))
```

Then we can install COMPSs with:

```bash
# Load order might be important
ml PDCOLD/24.11
module use <pathToModules>/modules
ml java/21
ml boost/1.85.0-cpeGNU-24.11
ml all-spack-modules/0.23.1 # required for the following Python version
ml python/3.13.0-gcc-cgo
ml gcc/12.2.0
python -m ensurepip --upgrade
python -m pip install --user wheel setuptools --upgrade

wget https://compss.bsc.es/repo/sc/stable/COMPSs_3.4.tar.gz
tar -xvzf COMPSs_3.4.tar.gz
cd COMPSs
./install -T <proj>/installation/compss_3_4 dardel.cfg
```

And generated the following **Lua** module (for the `Lmod` system) in `<pathToModules>/modules/compss/3.4.lua`:

```lua
-- -*- lua -*-

local compss_home = "<pathToInstallation>/installation/compss_3_4/"

prepend_path("MODULEPATH", "<pathToModules>/modules")

depends_on("PDCOLD/24.11")
depends_on("all-spack-modules/0.23.1")
depends_on("boost/1.85.0-cpeGNU-24.11")
depends_on("python/3.13.0-gcc-cgo")
depends_on("java/21")

source_sh("bash", pathJoin(compss_home, "compssenv"))

setenv("COMPSS_HOME", compss_home)
```

The Gromacs version tested is `gromacs/2026.1-cpeGNU-24.11`.


#### **[Experimental]** Installation using Spack

!!! warning
    This installation is experimental and not directly supported by the COMPSs' Team. If issues arises, please refer to the officially supported [manual installation](#recommended-manual-installation-example)

??? info "Spack references"
    - [Add a package to Spack](https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html#package-creation-tutorial)
    - [Advance packaging tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html)
    - Reference files in directory [spack](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/docs/spack)

!!! info
    This repository contains two `package.py` depending on the Spack version. `0_22/compss/package.py` has been tested with Spack `<= 0.22.x`. `1_00/compss/package.py` has been tested with Spack `1.0 > <= 1.2`.

    If you encounter any issues in the process, read the [troubleshooting section](#troubleshoot) before open an issue.

These steps assume that Spack is available in your shell. It might be loaded in your HPC environment, for example using `module load spack`.

If you already have a Spack custom repo (in this example, the namespace is called `<repo name>`), skip to step 2, otherwise start from 1 creating a custom repo. Custom repos are required because most probably you won't have the permission to add software to the main repo of your cluster.

**1. Create a personal repo**

```bash
spack repo create path/to/root/repos <repo name>
spack repo add path/to/root/repos/<repo name>
```

This will create a new repository, and a namespace, where to add recipes for softwares called `<repo name>`.

**2. Add COMPSs to the repo**

```bash
spack create --name compss -N <repo name>
```

Then you will be prompted with the default editor to update the `package.py` of COMPSs that you can close. Overwrite the content of `spack edit compss` with the `package.py` from this repo:

```bash
cp <this repo>/docs/spack/<spack_version>/compss/package.py path/to/root/repos/<repo name>/packages/compss/
```

**3. Install COMPSs**

Concretize the spec and install COMPSs, specifying the `cfg` through the environment variable `COMPSS_SUPERCOMPUTER_CFG` (only the filename):

```bash
spack spec -Il compss
```

```bash
COMPSS_SUPERCOMPUTER_CFG=leonardo.cfg spack install compss
```

**4. Generate the Tcl module**

Load environment variables and add binaries to `PATH`:

```bash
spack module tcl refresh -y
```

Now, load COMPSs in the current shell:

```bash
module load compss
```

The full name will look something like `compss/3.3.3--gcc--12.2.0`. Alternatively:

```bash
spack load compss
```

To test the installation just type `enqueue_compss --version`.


#### Troubleshoot

??? note "The user cannot create a personal repo in the cluster"

    If this operation results in permission errors in your cluster, probably the user is not allowed to have a personal `repo.yaml` file.
    In this case, contact your system administrator. A possible solution could be [re-enable the user to perform such operation](https://spack.readthedocs.io/en/latest/configuration.html#overriding-local-configuration) specifying `unset SPACK_DISABLE_LOCAL_CONFIG`

??? note "COMPSs cannot be found when creating the Spack spec"

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


??? note "Errors while compiling COMPSs with gcc 13 or later"

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


??? note "Cannot install PyCOMPSs because no `pip` available"

    In this case, you need to install `pip` within the Python interpreter that you use to install PyCOMPSs and run workflows. Follow the [official documentation](https://pip.pypa.io/en/stable/installation/) for this.

    Be aware that if you install `pip` and PyCOMPSs within a `venv`, PyCOMPSs will be installed **only** on that virtual environment. Therefore, you will need to always source it to run a workflow. We discourage the latter approach.


??? note "No module compss when using module load"

    If you cannot find the `compss` module, you need to issue first (or append to your shell config file, e.g. `~/.bashrc`, to make it permanent) `module use --append $SPACK_HOME/modules/` or the location where Spack creates modules.


??? note "`enqueue_compss` runs but it cannot find other binaries"

    If binaries like `enqueue_compss` or related are in the `PATH` variable, but do not work when invoked, inspect the module file generated with `ml show compss`. A common problem is an incorrect `COMPSS_HOME` environmental variable.

    To fix this, you need to modify accordingly to the error the `package.py` file in the `env.set("COMPSS_HOME", compss_home)` line.

### Post-installation configuration

COMPSs uses [configuration files to adapt to different clusters](https://compss-doc.readthedocs.io/en/stable/Sections/01_Installation_Configuration/03_Configuration/02_Supercomputer.html). The general structure is the following:

![compss configs](https://compss-doc.readthedocs.io/en/stable/_images/queue_scripts_structure.png)

where `sc.cfg` is the supercomputer config file and `queue_system.cfg` is the confif file for the job scheduler.

#### Supercomputer

This file is selected during [installation](#installation-on-hpc) when calling `./install` or with the env var `COMPSS_SUPERCOMPUTER_CFG`. Afterward, it is renamed as `default.cfg` in the COMPSs installation directory (`<targetDir>Runtime/scripts/queues/supercomputers/default.cfg` or `$COMPSS_HOME/Runtime/scripts/queues/supercomputers/default.cfg`), where config files for other clusters are.

Supercomputers `cfg` files contains a set of variables to indicate the queue system used by a supercomputer, paths where the shared disk is mounted, etc.
These files are provided with the COMPSs installation, already tuned for different supercomputers by the BSC team.
We suggest taking a look at them to have an idea of the default parameters. If not specified in the `enqueue_compss` flags, the `default.cfg` one is picked.

For reproducibility, in this repo the `cfg` files stored in [`supercomputer_configs`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/docs/supercomputer_configs) are tested to work with the implementation of the [`md`](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/md) workflow.

#### Queue system (scheduler)

The `cfg` files contain a set of variables which are used by the other scripts. On one hand, the queue system `cfg`s contain variables to indicate the commands used by the system to submit and spawn processes, the commands or variables to get the allocated nodes and the directives to indicate the number of nodes, processes, etc.
These are container in `$COMPSS_HOME/Runtime/scripts/queues/queue_systems/`.

_The user is advice to not change them_.

---

## GROMACS

!!! warning

      We strongly suggest to follow [the official documentation](https://manual.gromacs.org/current/install-guide/index.html), the following are demostrations for specific systems that are not necessarly the best configuration for that system

??? Example "Example of manual installation on [Leonardo](https://docs.hpc.cineca.it/hpc/leonardo.html#leonardo-card)"

    The main idea is to have GROMACS relying on installed libraries and softwares to exploit their optimization for the specific cluster.

    By loading the `cuda` module, `nvcc` will be available to GROMACS. Moreover, `cmake` is able to find cuFFT from the `LD_LIBRARY_PATH`.

    Procedure:

    ```bash
    ml gcc/12.2
    ml cuda/12.2
    ml openmpi/4.1.6--gcc--12.2.0-cuda-12.2
    ml fftw/3.3.10--openmpi--4.1.6--gcc--12.2.0-spack0.22
    ml cmake/4.1.2
    ml openblas/0.3.26--gcc--12.2.0
    ml netlib-scalapack/2.2.0--openmpi--4.1.6--gcc--12.2.0-spack0.22
    ml hdf5/1.14.3--openmpi--4.1.6--gcc--12.2.0-spack0.22

    tar xfz gromacs-2026.3.tar.gz
    cd gromacs-2026.3
    mkdir build
    cd build
    cmake .. -DGMX_MPI=on -DGMX_GPU=CUDA -DCMAKE_INSTALL_PREFIX=$PUBLIC/gromacs/gromacs_2026_3 -DGMX_FFT_LIBRARY=fftw3 -DCMAKE_CUDA_ARCHITECTURES=80 -DREGRESSIONTEST_DOWNLOAD=ON

    # entering a Leonardo DCGP compute node
    srun -A cin_staff -p dcgp_usr_prod -N1 -n16 -t 02:00:00 --pty /bin/bash
    make -j 16
    make check -j 16
    make install
    ```

    Then, one needs to prepare a module file in `<pathToModules>/gromacs/2026.3`, such as:

    ```tcl
    #%Module

    module-whatis "GROMACS is a molecular dynamics package primarily designed for simulations of proteins, lipids and nucleic acids. It was originally developed in the Biophysical Chemistry department of University of Groningen, and is now maintained by contributors in universities and research centers across the world."


    proc ModulesHelp { } {
    puts stderr "Loads GROMACS 2026.3"
    }

    set GROMACS_HOME "$PUBLIC/gromacs/gromacs_2026_3"
    source-sh bash ${GROMACS_HOME}/bin/GMXRC

    prereq gcc
    prereq cuda/12.2
    prereq openmpi/4.1.6--gcc--12.2.0-cuda-12.2
    prereq fftw/3.3.10--openmpi--4.1.6--gcc--12.2.0-spack0.22
    prereq openblas/0.3.26--gcc--12.2.0
    prereq netlib-scalapack/2.2.0--openmpi--4.1.6--gcc--12.2.0-spack0.22
    prereq hdf5/1.14.3--openmpi--4.1.6--gcc--12.2.0-spack0.22
    ```

    Note that we need to make all the dynamically linked libraries available at runtime. Moreover, we just need to source with [`source-sh`](https://modules.readthedocs.io/en/latest/modulefile.html#mfcmd-source-sh) the bash script provided by GROMACS.
