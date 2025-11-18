> [!WARNING]
> To run one of these examples with the workflow `md` you find in this repo, be sure to have downloaded and set in the scripts the path to the CHARMM36 FF.

## pdb
A couple of globular proteins that are fast to test.

## haddock
A set of structures derived from HADDOCK predictions.

> [!WARNING]
> Note that pdb files coming from Haddock are corrently lacking a clear `ter` keywork at the end of the polypeptide chains. This causes Gromacs (as in version `2025.3`) to not be able to automatically chose the protonation state of the chains termini. To solve this, pdb files has to be pre-processed interactively before the workflow run in `md`.
>
> This can be done using the script [`pdb2gmx_wrapper.sh`](./../workflow/scripts/pdb2gmx_wrapper.sh) in which one can add the `-ter` option to `pdb2gmx`, which interactively let you choose the protonation.
>
> For more info, see [branch `example-3vxm-kth` of this repo](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/tree/example-3vxm-kth).