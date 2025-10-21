# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
#
#     spack install compss
#
# You can edit this file again by typing:
#
#     spack edit compss
#
import os

from docs.spack.compss.package import *

class Compss(Package):
    """COMP Superscalar (COMPSs)/pyCOMPSs is a task-based programming model which aims to ease the development of applications for distributed infrastructures, such as large High-Performance clusters (HPC), clouds and container managed clusters. COMPSs provides a programming interface for the development of the applications and a runtime system that exploits the inherent parallelism of applications at execution time."""

    homepage = "https://compss.bsc.es"
    url = "https://compss.bsc.es/repo/sc/stable/COMPSs_3.3.3.tar.gz"

    maintainers("lsalicar")

    version("3.3.3", sha256="7b0e52e275b3890aa59f5b5ae40e13b49701269c8d1b2ff76c0aed27d30d6239")

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

    variant('supercomputer_cfg', values=str, description='Configuration file of the supercomputer where to install')

    def setup_build_environment(self, env, spec):
        env.set("BOOST_CPPFLAGS", "-std=c++11 -pthread -O2 -s")
        env.set("JAVA_HOME", self.spec["openjdk"].prefix)

    def install(self, spec, prefix):
        if 'supercomputer_cfg' not in spec.variants or spec.variants['supercomputer_cfg'].value is None:
            raise InstallError('Variant "supercomputer_cfg" must be specified with +supercomputer_cfg=<value> on the command line')
        selected_cfg = spec.variants['supercomputer_cfg'].value
        install_script = Executable('./install')
        install_script(
            '-T',
            prefix.compss,
            os.path.join(prefix.compss, "Runtime/scripts/queues/supercomputers", selected_cfg))

    def setup_run_environment(self, env):
        env.from_sourcing_file(os.path.join(self.prefix.compss, "compssenv"))
