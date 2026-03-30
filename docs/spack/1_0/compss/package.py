# Copyright 2013-2024 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
#
# File for Spack > 1.0
import os

from spack.package import *

class Compss(Package):
    """COMP Superscalar (COMPSs)/pyCOMPSs is a task-based programming model which aims to ease the development of applications for distributed infrastructures, such as large High-Performance clusters (HPC), clouds and container managed clusters. COMPSs provides a programming interface for the development of the applications and a runtime system that exploits the inherent parallelism of applications at execution time.

    Warning: This installation focus on Python bindings
    """

    homepage = "https://compss.bsc.es"
    url = "https://compss.bsc.es/repo/sc/stable/COMPSs_3.4.tar.gz"

    maintainers("lsalicar")

    version("3.4", sha256="32dd2b2dc8be4a0a08705f9c2c86508ba491d32addcee2d961504defeb569af4")
    version("3.3.3", sha256="7b0e52e275b3890aa59f5b5ae40e13b49701269c8d1b2ff76c0aed27d30d6239")

    depends_on("c", type="build")
    depends_on("cxx", type="build")

    # Versions for python bindings taken from
    # compss/programming_model/bindings/python/pyproject.toml
    depends_on('py-setuptools@0.61:', type='build')
    depends_on("py-wheel@0.43.0:", type="build")
    depends_on('py-cython', type='build')
    depends_on("py-pip", type="build")
    depends_on('autoconf', type='build')
    depends_on('automake', type='build')
    depends_on('libtool', type='build')
    depends_on('m4', type='build')
    depends_on('boost', type='build')
    depends_on('libxml2', type='build')
    depends_on('python@:3.12', type=('build', 'link', 'run'))
    depends_on('openjdk@:21', type=('build', 'link', 'run'))
    # Optional dipendencies
    # https://compss-doc.readthedocs.io/en/3.4/Sections/01_Installation_Configuration/01_Dependencies/02_Supercomputer.html#optional-dependencies
    # WARNING: the guppy3 package is missing, hence if you are using the
    # @local decorator, please add it to your Python env
    depends_on('py-dill', type='run')
    depends_on('py-numpy', type='run')
    # # Needed for Provenance reports
    depends_on('py-pyyaml', type='run')
    depends_on('py-rocrate', type='run')
    depends_on('py-pytz', type='run')

    def install(self, spec, prefix):
        # FIXME: modify BOOST_CPPFLAGS if your installation differs from this
        # c++11 is the default in the spack package, check there for other options
        os.environ['BOOST_CPPFLAGS'] = '-std=c++11 -pthread -O2 -s'
        os.environ['JAVA_HOME'] = self.spec["openjdk"].prefix

        selected_cfg = os.environ.get('COMPSS_SUPERCOMPUTER_CFG', "")
        if not selected_cfg:
            raise InstallError('Environment variable COMPSS_SUPERCOMPUTER_CFG must be set to the config filename')
        install_script = Executable('./install')
        # We need to specify as target dir (the second argument below)
        # the path: `os.path.join(prefix, "compss")`
        # We cannot install in `prefix` because the current (@:3.4) COMPSs
        # install.sh script does a `rm -r` and recreate that directory.
        # This causes Spack to remove that directory at the end of the
        # installation, invalidating the whole installation.
        install_script(
            '-T',
            os.path.join(prefix, "compss"),
            selected_cfg
        )

    def setup_run_environment(self, env):
        # Perform the same operations as builders/specs/sc/compssenv
        compss_home = os.path.join(self.prefix, "compss")
        env.append_path('PATH', os.path.join(compss_home, 'Runtime/scripts/user'))
        env.append_path('PATH', os.path.join(compss_home, 'Runtime/scripts/utils'))
        env.append_path('PATH', os.path.join(compss_home, 'CLI'))
        env.append_path('PATH', os.path.join(compss_home, 'Bindings/c/bin'))
        env.append_path('CLASSPATH', os.path.join(compss_home, 'Runtime/compss-engine.jar'))
        env.append_path('PYTHONPATH', os.path.join(compss_home, 'Bindings/python/'))
        if self.spec.satisfies('@3.4'):
            # R Bindings
            env.append_path('R_LIBS_USER', os.path.join(compss_home, 'Bindings/RCOMPSs/user_libs/'))

        env.set("COMPSS_HOME", compss_home)
