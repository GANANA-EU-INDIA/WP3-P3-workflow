import argparse
import os
from pathlib import Path

from pycompss.api.api import compss_barrier, compss_snapshot
from pycompss.api.binary import binary
from pycompss.api.constraint import constraint
from pycompss.api.mpi import mpi
from pycompss.api.parameter import (
    FILE_IN,
    FILE_IN_STDIN,
    FILE_INOUT,
    FILE_OUT,
    FILE_OUT_STDOUT,
    IN,
    Type,
)
from pycompss.api.task import task

# =========== ====================== =========== #
# ===========     GLOBAL VARIABLES   =========== #
# =========== ====================== =========== #
# Load environmental variables
COMPSS_HOME = os.environ["COMPSS_HOME"]
GMXBIN_NAME = os.environ["GMXBIN_NAME"]

# Arguments to control OpenMP threads etc.
# NOTE: it can be changed in the Worflow, placed here for convinience
OPENMP_THREADS = 8


parser = argparse.ArgumentParser()
parser.add_argument(
    "--dataset",
    "-d",
    type=str,
    required=True,
    help="Dataset absolute path with PDBs and Gromacs mdm files",
)
parser.add_argument(
    "--output", "-o", type=str, required=True, help="Output absolute path"
)
args = parser.parse_args()


# =========== ====================== =========== #
# ===========          TASKS         =========== #
# =========== ====================== =========== #