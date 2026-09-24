# Free energies calculations workflow

Technical notes:
- Free energies in this context refer to the $\Delta \Delta G$ of the TCR recognition
- Mutation are performed at the peptide level, and are single point (one residue at the time) mutations
- For simplicity, we considere one TCR per epitope at the time
- Free energies will be computed with alchemical trasformation, where the alchemical cycle will include Wild Type (WT) and mutated (M) versions of the peptide binded to the MHC, and the same WT and M versions but with the TCR binded
- `pmx` will be use for the setup of the system, hence for [mutation and creation of the hybrid topology](http://pmx.mpibpc.mpg.de/sardinia2018_tutorial1/index.html)
- The AHW method, which is an enhenced sampling method, in Gromacs will be used to [sample the transition between WT and M versions](https://gitlab.com/gromacs/online-tutorials/awh-free-energy-of-solvation/-/blob/main/tutorial.ipynb?ref_type=heads), for both systems
- The forcefield is consistent with the one used in the MD wortkflow, hence `charmm36-jul2022`
- Equilibrium starting states for the WT version are taken from the production run of the MD workflow
- All parameters of the sampling are handled by `mdp` files