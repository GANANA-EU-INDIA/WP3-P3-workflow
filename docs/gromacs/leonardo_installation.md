## Manual installation on Leonardo (no spack)

Rationale:

- mport as many library from Leonardo as possible
- avoid nvhpc-based libraries

Since I've loaded `cuda`, `nvcc` will be available to Gromacs. I've also checked that `cmake` is able to find cuFFT in the `cuda` libraries.

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

# enter a Leonardo compute node
srun -A cin_staff -p dcgp_usr_prod -N1 -n16 -t 02:00:00 --pty /bin/bash
make -j 16 
make check -j 16
make install
```

Then, one needs to prepare a module file in `<pathToModules>/gromacs/2026.3`:

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

Note that we need to make all the dynamically linked libraries available at runtime. Moreover, we just need to source with [`source-sh`](https://modules.readthedocs.io/en/latest/modulefile.html#mfcmd-source-sh) the bash script provided by Gromacs.
