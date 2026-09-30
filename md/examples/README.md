> [!WARNING]
> To run one of these examples with the workflow `md` you find in this repo, be sure to have downloaded and set in the scripts the path to the CHARMM36 FF.

## `pdb`
A couple of globular proteins that are fast to test.

Each protein directory contains:
- A PDB file (input structure)
- `select.txt` (selection file for `pdb2gmx` chain termini protonation states)
- MD parameter files: `emin-charmm.mdp`, `nvt-charmm.mdp`, `npt-charmm.mdp`, `md-charmm.mdp`

## `from_modelling`
A set of structures derived from HADDOCK predictions.

> [!WARNING]
> Note that `pdb` files coming from Haddock lack a `ter` keyword at the end of the polypeptide chains. This causes GROMACS to not being able to automatically find the chains termini. Hence, a `-ter` flag in the `pdb2gmx` command is necessary.