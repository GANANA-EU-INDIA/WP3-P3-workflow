import argparse
import os
import sys
from pathlib import Path

from pycompss.api.binary import binary
from pycompss.api.mpi import mpi
from pycompss.api.parameter import FILE_IN, FILE_INOUT, FILE_OUT, IN
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
    help="Dataset absolute path with GRO files, MDP files and precomputed topologies",
)
parser.add_argument(
    "--output", "-o", type=str, required=True, help="Output absolute path"
)
args = parser.parse_args()


# =========== ====================== =========== #
# ===========          TASKS         =========== #
# =========== ====================== =========== #


@binary(
    binary="pmx",
    args="mutate -f {{pdb_in}} -o {{pdb_out}} -ff {{ff}} --keep_resid --script {{mutation_list}}",
)
@task(pdb_in=FILE_IN, mutation_list=FILE_IN, pdb_out=FILE_OUT)
def mutate(pdb_in, mutation_list, pdb_out, ff) -> None:
    """mutate -f pdb_in -o pdb_out -ff ff --keep_resid --script mutation_list

    Select chain (--keep_reid), residue and mutation with script; outputs mutant structure file.
    """
    pass


@binary(
    binary="pmx",
    args="gentop -p {{topology_in}} -o {{topology_out}} -ff {{ff}}",
)
@task(topology_in=FILE_IN, topology_out=FILE_OUT)
def generate_hybrid_topology(topology_in, topology_out, ff) -> None:
    """gentop -p topology_in -o topology_out -ff {{ff}}

    Post-process topology to add morphing parameters for alchemical mutation.
    """
    pass


# Ensure parent directory (md/) is on sys.path for sibling module imports
if str(Path(__file__).parent.parent) not in sys.path:
    sys.path.insert(0, str(Path(__file__).parent.parent))

# npt_preprocess and npt are reused from md.py
from md import npt, npt_preprocess  # noqa: E402


# =========== ====================== =========== #
# =========== WORKFLOW SPECIFICATION =========== #
# =========== ====================== =========== #
def main() -> None:
    dataset = args.dataset
    output_dir = args.output

    # Checks
    dataset = Path(dataset).absolute().resolve()
    if not dataset.exists():
        raise FileNotFoundError(f"Dataset {str(dataset)} does not exist.")
    output_dir = Path(output_dir).absolute().resolve()
    if not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)

    protein_dirs = [d for d in dataset.iterdir() if d.is_dir()]
    print(f"Protein directories found:\n{protein_dirs}")

    for protein_dir in protein_dirs:
        gro_files = list(protein_dir.glob("*.gro"))
        if not gro_files:
            print(f"No .gro files in {protein_dir}, skipping.")
            continue
        gro = gro_files[0]  # first .gro per directory
        print(f"gro file used: {str(gro)}")

        # create sub-directory for each protein
        output_subdir = output_dir / protein_dir.name
        output_subdir.mkdir(parents=True, exist_ok=True)

        # +++++++++++ Mutation
        ff = "charmm36-jul2022"
        mutation_list = str(protein_dir / "mutation_list.txt")
        mutant_gro = str(output_subdir / "mutant.gro")
        mutate(str(gro), mutation_list, mutant_gro, ff=ff)

        # +++++++++++ Generate Hybrid Topology
        input_topology = str(protein_dir / "topology.top")
        hybrid_topology = str(output_subdir / "hybrid.top")
        generate_hybrid_topology(input_topology, hybrid_topology, ff=ff)

        # +++++++++++ Production run
        awh_mdp = str(dataset / "fep_awh_alchemical.mdp")
        awh_tpr = str(output_subdir / "awh.tpr")
        npt_preprocess(
            npt_mdp=awh_mdp,
            protein_eq=mutant_gro,
            topology=hybrid_topology,
            npt_tpr=awh_tpr,
        )

        awh_log = str(output_subdir / "awh_log.log")
        protein_awh = str(output_subdir / "protein_awh.gro")
        awh_cpt = str(output_subdir / "awh_traj.cpt")
        awh_energy = str(output_subdir / "awh_energy.edr")
        npt(
            npt_tpr=awh_tpr,
            log=awh_log,
            protein_npt=protein_awh,
            npt_cpt=awh_cpt,
            npt_energy=awh_energy,
        )


if __name__ == "__main__":
    main()
