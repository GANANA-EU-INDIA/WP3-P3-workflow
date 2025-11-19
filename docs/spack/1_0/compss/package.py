# Copyright 2013-2024 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
#
# File for Spack > 1.0
import os

from spack.package import *

class Compss(Package):
    """COMP Superscalar (COMPSs)/pyCOMPSs is a task-based programming model which aims to ease the development of applications for distributed infrastructures, such as large High-Performance clusters (HPC), clouds and container managed clusters. COMPSs provides a programming interface for the development of the applications and a runtime system that exploits the inherent parallelism of applications at execution time."""

    homepage = "https://compss.bsc.es"
    url = "https://compss.bsc.es/repo/sc/stable/COMPSs_3.3.3.tar.gz"

    maintainers("lsalicar")

    version("3.3.3", sha256="7b0e52e275b3890aa59f5b5ae40e13b49701269c8d1b2ff76c0aed27d30d6239")

    depends_on("c", type="build")
    depends_on("cxx", type="build")

    depends_on('py-setuptools', type='build')
    depends_on("py-pip", type="build")
    depends_on("py-wheel", type="build")
    depends_on('autoconf', type='build')
    depends_on('automake', type='build')
    depends_on('libtool', type='build')
    depends_on('m4', type='build')
    depends_on('boost', type='build')
    depends_on('libxml2', type='build')
    depends_on('python@3.11')
    depends_on('openjdk')

    def install(self, spec, prefix):
        # FIXME: modify BOOST_CPPFLAGS if your installation differs from this
        os.environ['BOOST_CPPFLAGS'] = '-std=c++11 -pthread -O2 -s'
        os.environ['JAVA_HOME'] = self.spec["openjdk"].prefix

        selected_cfg = os.environ.get('COMPSS_SUPERCOMPUTER_CFG', "")
        if not selected_cfg:
            raise InstallError('Environment variable COMPSS_SUPERCOMPUTER_CFG must be set to the config filename')
        install_script = Executable('./install')
        # We need to specify as target dir (the second argument below)
        # the path: `os.path.join(prefix, "compss")`
        # We cannot install in `prefix` because the current COMPSs
        # install.sh script does a `rm -r` and recreate that directory.
        # This causes Spack to remove that directory at the end of the
        # installation, invalidating the whole installation.
        install_script(
            '-T',
            os.path.join(prefix, "compss"),
            selected_cfg
        )

    def setup_run_environment(self, env):
        compss_home = os.path.join(self.prefix, "compss")
        env.append_path('PATH', os.path.join(compss_home, 'Runtime/scripts/user'))
        env.append_path('PATH', os.path.join(compss_home, 'Runtime/scripts/utils'))
        env.append_path('PATH', os.path.join(compss_home, 'CLI'))
        env.append_path('PATH', os.path.join(compss_home, 'Bindings/c/bin'))
        env.append_path('CLASSPATH', os.path.join(compss_home, 'Runtime/compss-engine.jar'))
        env.append_path('PYTHONPATH', os.path.join(compss_home, 'Bindings/python/'))

        env.set("COMPSS_HOME", compss_home)
