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


@binary(
    binary="pdb_delhetatm",  # the bin absolute path is in PATH when venv is active
)
@task(pdb_original=FILE_IN, pdb_protein_only={Type: FILE_OUT_STDOUT})
def remove_heteratom(pdb_original, pdb_protein_only) -> None:
    """pdb_delhetatm < pdb_original > pdb_protein_only
    Remove HETATOM from the PDB

    Note: pdb_delhetatm removes CONECT lines related to HETATM removed
    """
    pass


@binary(
    binary=GMXBIN_NAME,
    args="pdb2gmx -f {{protein}} -o {{structure}} -p {{topology}} -ignh -ff {{ff}} -water {{water}} -merge all",
)
@task(protein=FILE_IN, structure=FILE_OUT, topology=FILE_OUT)
def generate_topology(protein=None, structure=None, topology=None, ff=None, water=None) -> None:
    """
    """
    pass


@binary(
    binary=GMXBIN_NAME,
    args="editconf -f {{structure_processed}} -o {{structure_box}} -c -d 1.0 -bt triclinic",
)
@task(structure_processed=FILE_IN, structure_box=FILE_OUT)
def define_box(structure_processed=None, structure_box=None) -> None:
    """Create structure file with simulation box"""
    pass


@binary(
    binary=GMXBIN_NAME,
    args="solvate -cp {{structure_box}} -cs spc216.gro -o {{protein_solvated}} -p {{topology}}",
)
@task(structure_box=FILE_IN, protein_solvated=FILE_OUT, topology=FILE_INOUT)
def solvate(
    structure_box=None,
    protein_solvated=None,
    topology=None,  # note: the top file is modified hence is used as input
) -> None:
    """Introduce generic equilibrate 3-point solvent and modify top file"""
    pass


@binary(
    binary=GMXBIN_NAME,
    args="grompp -f {{ions}} -c {{protein_solvated}} -p {{topology}} -o {{ions_tpr}}",
)
@task(
    ions=FILE_IN,
    protein_solvated=FILE_IN,
    topology=FILE_INOUT,
    ions_tpr=FILE_OUT,
)
def ions_preprocess(
    ions=None,
    protein_solvated=None,
    topology=None,
    ions_tpr=None,
) -> None:
    """Preprocess to ions insertion"""
    pass


@binary(
    binary=GMXBIN_NAME,
    args="genion -s {{ions_tpr}} -o {{protein_ions}} -conc 0.15 -p {{topology}} -pname NA -nname CL -neutral",
)
@task(
    ions_tpr=FILE_IN,
    protein_ions=FILE_OUT,
    topology=FILE_INOUT,
    ion_type_selection={Type: FILE_IN_STDIN},
)
def ions_substitution(
    ions_tpr=None,
    protein_ions=None,
    topology=None,
    ion_type_selection=None,
) -> None:
    """command < genions.group

    Ions insertion to have a neutrilized system
    """
    pass


@binary(
    binary=GMXBIN_NAME,
    args="grompp -f {{emin_mdp}} -c {{protein_ions}} -p {{topology}} -o {{emin_tpr}}",
)
@task(
    emin_mdp=FILE_IN,
    protein_ions=FILE_IN,
    topology=FILE_INOUT,
    emin_tpr=FILE_OUT,
)
def emin_preprocess(
    emin_mdp=None, protein_ions=None, topology=None, emin_tpr=None
) -> None:
    """Preprocess for energy minimization"""
    pass


# Note that computing units here are used to specify
# the number of cores available for the task (< than the available CPUS_PER_NODE).
# In this case, it is use to specify the number of OpenMP threads
@constraint(computing_units=OPENMP_THREADS)
@binary(
    binary=GMXBIN_NAME,
    args="mdrun -s {{emin_tpr}} -c {{protein_emin}} -ntomp {{omp}} -g {{log}} -e {{energy_file}}",
)
@task(
    emin_tpr=FILE_IN, protein_emin=FILE_OUT, omp=IN, log=FILE_OUT, energy_file=FILE_OUT
)
def enmin(
    emin_tpr=None,
    protein_emin=None,
    omp=OPENMP_THREADS,
    log=None,
    energy_file=None,
) -> None:
    """Energy minimization"""
    pass


@binary(
    binary=GMXBIN_NAME,
    args="grompp -f {{nvt_mdp}} -c {{protein_eq}} -r {{protein_eq}} -p {{topology}} -o {{nvt_tpr}}",
)
@task(
    nvt_mdp=FILE_IN,
    protein_eq=FILE_IN,
    topology=FILE_INOUT,
    nvt_tpr=FILE_OUT,
)
def nvt_preprocess(nvt_mdp=None, protein_eq=None, topology=None, nvt_tpr=None) -> None:
    """Preprocess for NVT equilibratrion simulation"""
    pass


@constraint(
    processors=[
        {"processorType": "CPU", "computingUnits": OPENMP_THREADS},
        {"processorType": "GPU", "computingUnits": "1"},
    ]
)
@mpi(
    runner="mpirun",
    binary=GMXBIN_NAME,
    processes_per_node=1,
    args="mdrun -s {{nvt_tpr}} -ntomp {{omp}} -pin on -nb gpu -pme gpu -pmefft gpu -bonded gpu -update gpu -g {{log}} -c {{protein_nvt}} -cpo {{nvt_cpt}} -e {{nvt_energy}}",
)
@task(
    nvt_tpr=FILE_IN,
    omp=IN,
    log=FILE_OUT,
    protein_nvt=FILE_OUT,
    nvt_cpt=FILE_OUT,
    nvt_energy=FILE_OUT,
)
def eq_nvt(
    nvt_tpr=None,
    omp=OPENMP_THREADS,
    log=None,
    protein_nvt=None,
    nvt_cpt=None,
    nvt_energy=None,
) -> None:
    """Perform the equilibration NVT simulation"""
    pass


@binary(
    binary=GMXBIN_NAME,
    args="grompp -f {{npt_mdp}} -c {{protein_eq}} -r {{protein_eq}} -p {{topology}} -o {{npt_tpr}}",
)
@task(
    npt_mdp=FILE_IN,
    protein_eq=FILE_IN,
    topology=FILE_INOUT,
    npt_tpr=FILE_OUT,
)
def npt_preprocess(
    npt_mdp=None,
    protein_eq=None,
    topology=None,
    npt_tpr=None,
) -> None:
    """Preprocess for NPT equilibratrion simulation"""
    pass


@constraint(
    processors=[
        {"processorType": "CPU", "computingUnits": OPENMP_THREADS},
        {"processorType": "GPU", "computingUnits": "1"},
    ]
)
@mpi(
    runner="mpirun",
    binary=GMXBIN_NAME,
    processes_per_node=1,
    args="mdrun -s {{npt_tpr}} -ntomp {{omp}} -pin on -nb gpu -pme gpu -pmefft gpu -bonded gpu -update gpu -g {{log}} -c {{protein_npt}} -cpo {{npt_cpt}} -e {{npt_energy}}",
)
@task(
    npt_tpr=FILE_IN,
    omp=IN,
    log=FILE_OUT,
    protein_npt=FILE_OUT,
    npt_cpt=FILE_OUT,
    npt_energy=FILE_OUT,
)
def npt(
    npt_tpr=None,
    omp=OPENMP_THREADS,
    log=None,
    protein_npt=None,
    npt_cpt=None,
    npt_energy=None,
) -> None:
    """Perform the equilibration NPT simulation"""
    pass


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

    pdb_files = list(dataset.glob("*.pdb"))
    print(f"PDBs found:\n{pdb_files}")

    out = {}

    for pdb in pdb_files:
        # create sub-directory for each protein
        output_subdir = output_dir / pdb.stem
        output_subdir.mkdir(parents=True, exist_ok=True)

        # +++++++++++ Cleaning input structures
        pdb_protein_only = str(output_subdir / "protein_only.pdb")
        remove_heteratom(str(pdb), pdb_protein_only)

        # +++++++++++ Generate Topology files
        topology = str(output_subdir / "topology.top")
        structure_processed = str(output_subdir / "structure_processed.gro")
        generate_topology(
            protein=pdb_protein_only, topology=topology, structure=structure_processed, ff="charmm36-jul2022", water="tip3p"
        )

        # +++++++++++ Solvation
        structure_box = str(output_subdir / "structure_box.gro")
        define_box(structure_processed=structure_processed, structure_box=structure_box)

        protein_solvated = str(output_subdir / "protein_solvated.gro")
        solvate(
            structure_box=structure_box,
            protein_solvated=protein_solvated,
            topology=topology,
        )

        # +++++++++++ Add Ions
        # Prepocess:
        # Here we just need the binary tpr file to forward to genions
        # Create an empty mdp file for the ions, no settings are required
        ions_mdp = output_subdir / "ions.mdp"
        ions_mdp.touch()
        ions_tpr = str(output_subdir / "ions.tpr")
        ions_preprocess(
            ions=str(ions_mdp),
            protein_solvated=protein_solvated,
            topology=topology,
            ions_tpr=ions_tpr,
        )
        group_file = output_subdir / "genions.group"
        with open(group_file, "w") as gf:
            gf.write("SOL\n")
        protein_neutralized = str(output_subdir / "protein_ions.gro")
        ions_substitution(
            ions_tpr=ions_tpr,
            protein_ions=protein_neutralized,
            topology=topology,
            ion_type_selection=str(group_file),
        )

        # +++++++++++ Energy Minimization
        emin_mdp = str(dataset / "emin-charmm.mdp")
        emin_tpr = str(output_subdir / "em.tpr")
        emin_preprocess(
            emin_mdp=emin_mdp,
            protein_ions=protein_neutralized,
            topology=topology,
            emin_tpr=emin_tpr,
        )
        protein_emin = str(output_subdir / "protein_emin.gro")
        emin_log = str(output_subdir / "emin_log.log")
        emin_file = str(output_subdir / "emin.edr")
        enmin(
            emin_tpr=emin_tpr,
            protein_emin=protein_emin,
            log=emin_log,
            energy_file=emin_file,
        )

        # +++++++++++ Energy Minimization Analysis

        # +++++++++++ Equilibration run
        # NVT
        nvt_mdp = str(dataset / "nvt-charmm.mdp")
        nvt_tpr = str(output_subdir / "nvt.tpr")
        nvt_preprocess(
            nvt_mdp=nvt_mdp,
            protein_eq=protein_emin,
            topology=topology,
            nvt_tpr=nvt_tpr,
        )

        nvt_log = str(output_subdir / "nvt_log.log")
        protein_nvt = str(output_subdir / "protein_nvt.gro")
        nvt_cpt = str(output_subdir / "nvt_traj.cpt")
        nvt_energy = str(output_subdir / "nvt_energy.edr")
        eq_nvt(
            nvt_tpr=nvt_tpr,
            log=nvt_log,
            protein_nvt=protein_nvt,
            nvt_cpt=nvt_cpt,
            nvt_energy=nvt_energy,
        )

        # NPT
        npt_mdp = str(dataset / "npt-charmm.mdp")
        npt_tpr = str(output_subdir / "npt.tpr")
        npt_preprocess(
            npt_mdp=npt_mdp,
            protein_eq=protein_nvt,
            topology=topology,
            npt_tpr=npt_tpr,
        )

        npt_log = str(output_subdir / "npt_log.log")
        protein_npt = str(output_subdir / "protein_npt.gro")
        npt_cpt = str(output_subdir / "npt_traj.cpt")
        npt_energy = str(output_subdir / "npt_energy.edr")
        npt(
            npt_tpr=npt_tpr,
            log=npt_log,
            protein_npt=protein_npt,
            npt_cpt=npt_cpt,
            npt_energy=npt_energy,
        )

        # save out variables
        out[pdb.stem] = [topology, protein_npt]

        # +++++++++++ Production run
        # Note: same structure and functions as eq
        prod_npt_mdp = str(dataset / "md-charmm.mdp")
        prod_npt_tpr = str(output_subdir / "prod_npt.tpr")
        npt_preprocess(
            npt_mdp=prod_npt_mdp,
            protein_eq=protein_npt,
            topology=topology,
            npt_tpr=prod_npt_tpr,
        )

        prod_npt_log = str(output_subdir / "prod_npt_log.log")
        protein_prod_npt = str(output_subdir / "protein_prod_npt.gro")
        prod_npt_cpt = str(output_subdir / "prod_npt_traj.cpt")
        prod_npt_energy = str(output_subdir / "prod_npt_energy.edr")
        npt(
            npt_tpr=prod_npt_tpr,
            log=prod_npt_log,
            protein_npt=protein_prod_npt,
            npt_cpt=prod_npt_cpt,
            npt_energy=prod_npt_energy,
        )


    #compss_barrier()
    #compss_snapshot()

    # for pdb in pdb_files:
    #     output_subdir = output_dir / pdb.stem

    #     topology = out[pdb.stem][0]
    #     protein_npt = out[pdb.stem][1]

    #     # +++++++++++ Production run
    #     # Note: same structure and functions as eq
    #     prod_npt_mdp = str(dataset / "md-charmm.mdp")
    #     prod_npt_tpr = str(output_subdir / "prod_npt.tpr")
    #     npt_preprocess(
    #         npt_mdp=prod_npt_mdp,
    #         protein_eq=protein_npt,
    #         topology=topology,
    #         npt_tpr=prod_npt_tpr,
    #     )

    #     prod_npt_log = str(output_subdir / "prod_npt_log.log")
    #     protein_prod_npt = str(output_subdir / "protein_prod_npt.gro")
    #     prod_npt_cpt = str(output_subdir / "prod_npt_traj.cpt")
    #     prod_npt_energy = str(output_subdir / "prod_npt_energy.edr")
    #     npt(
    #         npt_tpr=prod_npt_tpr,
    #         log=prod_npt_log,
    #         protein_npt=protein_prod_npt,
    #         npt_cpt=prod_npt_cpt,
    #         npt_energy=prod_npt_energy,
    #     )


if __name__ == "__main__":
    main()
