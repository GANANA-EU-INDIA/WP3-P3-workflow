This page documents PyCOMPSs installation/setup and GROMACS installation on various clusters as a reference.

## [Leonardo](https://docs.hpc.cineca.it/hpc/leonardo.html#leonardo-card) Booster

!!! info "Last update"
    2026/10/01

### PyCOMPSs

See [the main installation page](./installation.md).

### GROMACS

Already provided as a module by the CINECA team. An example of manual installation is the following.

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

## [Dardel](https://www.pdc.kth.se/hpc-services/computing-systems/dardel-hpc-system/about-the-dardel-system-1.1053338) gpu

!!! info "Last update"
    2026/10/31

### PyCOMPSs

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
ml PDC/26.03
module use <pathToModules>/modules
ml java/21
ml boost/1.90.0-cpeGNU-26.03
ml cray-python/3.12.12
ml gcc/12.2.0

wget https://compss.bsc.es/repo/sc/stable/COMPSs_3.4.tar.gz
tar -xvzf COMPSs_3.4.tar.gz
cd COMPSs
./install -T <pathToInstallation>/installation/compss_3_4 dardel.cfg
```

And generated the following **Lua** module (for the `Lmod` system) in `<pathToModules>/modules/compss/3.4.lua`:

```lua
-- -*- lua -*-

local compss_home = "<pathToInstallation>/installation/compss_3_4/"

prepend_path("MODULEPATH", "<pathToModules>/modules")

depends_on("PDC/26.03")
depends_on("boost/1.90.0-cpeGNU-26.03")
depends_on("cray-python/3.12.12")
depends_on("java/21")

source_sh("bash", pathJoin(compss_home, "compssenv"))

setenv("COMPSS_HOME", compss_home)
```

### GROMACS

The GROMACS version tested is `gromacs/2026.1-gpu-cpe2603-rocm7.0.2`, a module provided by the sysadmin.

## [Marenostrum5](https://www.bsc.es/marenostrum/marenostrum-5) ACC

!!! info "Last update"
    2026/10/01

### PyCOMPSs

Already provided as a module by the BSC team. The configuration file used is the one provided by default by COMPSs `mn5_acc.cfg`.

### GROMACS

Already provided as a module by the BSC team. An example of manual installation is the following.

Within the ACC login:
```bash
module load compenv-acc/gnu13.2.0-ompi # load compilation env
ml cmake/3.29 # required by recent GROMACS versions
module load cuda/12.8

cmake .. \
  -DGMX_FFT_LIBRARY=fftw3 -DGMX_BUILD_OWN_FFTW=OFF \
  -DREGRESSIONTEST_DOWNLOAD=OFF \
  -DGMX_GPU=CUDA \
  -DGMX_CUDA_TARGET_SM="90" -DGMX_CUDA_TARGET_COMPUTE="90" \
  -DCMAKE_INSTALL_PREFIX="/path/to/installations/gromacs/2026.4"
```
All downloading are set to `OFF` because MN5 nodes does not have internet access, otherwise the installation would hang.

## LUMI-G

!!! info "Last update"
    2026/10/01

### PyCOMPSs

Within a compute node, in an interactive session:
```bash
export JAVA_HOME=/users/salicari/jdk-27
ml PrgEnv-gnu/8.6.0
ml cray-python/3.11.7
export CFLAGS="-std=gnu17"
export BOOST_CPPFLAGS="-std=c++11 -pthread -O2 -s"
ml LUMI/25.03
ml Boost/1.88.0-cpeGNU-25.03

wget https://compss.bsc.es/repo/sc/stable/COMPSs_3.4.tar.gz
tar -xvzf COMPSs_3.4.tar.gz
cd COMPSs

# required because wheel and setuptools are not present by default
python -m pip install --upgrade pip setuptools wheel

./install -T /path/to/installation/compss/3.4 leonardo.cfg
```
`leonardo.cfg` is used as a placeholder. Lumi does not have a `cfg` file and therefore has to be created after installation. See our [`cfg` directory](https://github.com/GANANA-EU-INDIA/WP3-P3-workflow/tree/main/docs/supercomputer_configs) in the repository.

### GROMACS

It can be installed using the EasyBuild recipe provided:
```bash
module load LUMI/25.03
module load partition/G
module load EasyBuild-user
eb GROMACS-2026.0-cpeAMD-25.03-HeFFTe-rocm-hip.eb -r
```
For more recipe, see `eb -S gromacs`.
