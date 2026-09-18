import argparse
from collections import namedtuple
import csv
import matplotlib.pyplot as plt
import MDAnalysis as mda
from MDAnalysis.lib.distances import distance_array
import numpy as np

def compute_contact_matrix(contact_map, groupA, groupB, data_rows, data_cols, box=None):
    # This function computes the residue-level contact map between two atomGroups.
    # One value per residue pair is returned, which represents the minimum distance
    # between them.

    for res1 in groupA.residues:
        # Note: using resindex instead of residues is key for handling non-static
        # selections
        i = data_rows[res1.resindex]

        for res2 in groupB.residues:
            j = data_cols.get(res2.resindex)

            if j is None:
                continue

            # Find minimum distance between residues
            dist = distance_array(res1.atoms.positions, res2.atoms.positions, box=box)
            if dist.min() < 4.0:

                contact_map[i, j] += 1

    return contact_map

def create_global_residue_map(molecule):
    # Create dictionaries to map global residue indices with PDB residue labels.
    # This is useful when dealing with dynamic residue selections.

    resmap = {res.resindex: k for k, res in enumerate(molecule.residues)}
    return resmap

def visualize_contact_map(contact_map_MHC, contact_map_TCR, peptide, MHC, TCR, chain_map):

    # Extract the residue info
    peptide_data = get_residue_info(peptide, chain_map)
    MHC_data = get_residue_info(MHC, chain_map)
    TCR_data = get_residue_info(TCR, chain_map)

    # Make the axis labels for the plot
    def labels(group, info):
        return np.array([f"{info[res.resindex][0]}:{info[res.resindex][2]}"
                         for res in group.residues])

    peptide_labels = labels(peptide, peptide_data)
    MHC_labels = labels(MHC, MHC_data)
    TCR_labels = labels(TCR, TCR_data)

    # Shared color scale so both panels are directly comparable
    vmin = 0
    vmax = max(contact_map_MHC.max(), contact_map_TCR.max())

    fig, axes = plt.subplots(
        2, 1, figsize=(11, 9), sharex=True,
        gridspec_kw={"height_ratios": [MHC.residues.n_residues, TCR.residues.n_residues]}
    )
    fig.patch.set_facecolor("white")

    panel_specs = [
        (axes[0], contact_map_MHC, MHC_labels, "MHC Residue Number", "Peptide–MHC Contacts"),
        (axes[1], contact_map_TCR, TCR_labels, "TCR Residue Number", "Peptide–TCR Contacts"),
    ]

    for ax, cmap_data, labels, ylabel, title in panel_specs:

        # We only want to plot residues that are involved in contacts
        # Construct a filter that masks rows with only very small probability elements
        filter = np.any(np.abs(cmap_data) > 1e-6, axis=0)
        filtered_cmap = cmap_data[:, filter]

        yticklabels = labels[filter]


        im = ax.imshow(
            filtered_cmap.T, cmap="Reds", aspect="auto", origin="lower",
            vmin=vmin, vmax=vmax, interpolation="nearest"
        )

        ax.set_yticks(range(len(yticklabels)))
        ax.set_yticklabels(yticklabels, fontsize=11)
        ax.set_ylabel(ylabel, fontsize=14, fontweight="medium")
        ax.set_title(title, fontsize=15, fontweight="bold", loc="left", pad=8)

        # Subtle gridlines between cells for readability
        ax.set_xticks(np.arange(-0.5, len(peptide_labels), 1), minor=True)
        ax.set_yticks(np.arange(-0.5, len(yticklabels), 1), minor=True)
        ax.grid(which="minor", color="white", linewidth=0.5)
        ax.tick_params(which="minor", bottom=False, left=False)

        # Clean spines
        for spine in ax.spines.values():
            spine.set_visible(False)

    # X-axis only on bottom panel
    axes[1].set_xticks(range(len(peptide_labels)))
    axes[1].set_xticklabels(peptide_labels, fontsize=11, ha="right")
    axes[1].set_xlabel("Peptide Residue Number", fontsize=14, fontweight="medium")

    fig.subplots_adjust(right=0.88, hspace=0.15)
    cbar_ax = fig.add_axes([0.90, 0.15, 0.025, 0.7])
    cbar = fig.colorbar(im, cax=cbar_ax, label="Contact Probability")
    cbar.set_label("Contact Probability", fontsize=14, fontweight="medium")
    cbar.ax.tick_params(labelsize=11)
    cbar.outline.set_visible(False)

    fig.suptitle("Peptide Contact Maps", fontsize=17, fontweight="bold", y=0.98)

    #plt.savefig("Avg_contacts.png", dpi=600, bbox_inches="tight")
    plt.show()
    return

def get_residue_info(group, chain_map):
    """resindex -> (resid, resname, chain) for every residue in group."""
    info = {}
    for res in group.residues:
        ca = res.atoms.select_atoms("name CA")
        if len(ca):
            resid, chain = chain_map[ca.indices[0]]
        else:
            # No CA (non-standard residue, capping group): fall back on the
            # trajectory's own numbering and flag the unknown chain.
            resid, chain = res.resid, "?"
        info[res.resindex] = (resid, res.resname, chain)
    return info

def assign_chains_from_breaks(ca):

    positions = ca.positions
    distances = np.linalg.norm(np.diff(positions, axis=0), axis=1)

    break_indices = np.where(distances > 5.0)[0]
    print("Identified chain breaks between CA indices:", break_indices)

    # Split residues into chains based on breaks
    chains = []
    prev = 0
    for idx in break_indices:
        chains.append(ca.residues[prev:idx+1])
        prev = idx + 1
    chains.append(ca.residues[prev:])

    # Create a list of chain labels (ASCII 65 == "A")
    # WARNING: this will fail for systems with more than 26 chains!
    labels = [chr(65 + i) for i in range(len(chains))]

    # Create the chain mapping with arbitrary chain labels (A, B, C, ...)
    mapping = {}
    for k in range(len(chains)):
        mapping.update({res.atoms.select_atoms("name CA").indices[0] : (res.resid, labels[k]) for i, res in enumerate(chains[k])})

    return chains, mapping

def assign_chains_from_file(ca, structure_file):

    u_mol = mda.Universe(structure_file)
    protein_from_file = u_mol.select_atoms("protein and name CA")

    chainIDs = np.unique(protein_from_file.chainIDs)
    print("Identified chains from file: ", chainIDs)

    # Check that the reference file and trajectory contain the same number of residues
    if len(protein_from_file) == len(ca):

        # Extract chains from the reference file
        chain_lookup_from_file = [(atom.resid, atom.chainID) for atom in protein_from_file]

        # Map the chains from the reference file onto the structure.
        # NOTE: the mapping is based on residues/molecules appearing in the same order in both files!
        chain_mapping_onto_structure = {atom.index : (atom.resid, chain_lookup_from_file[i][1]) for i, atom in enumerate(ca)}

        # Find the atom groups based on chain IDs in the mapping
        chains = []
        for chain_id in chainIDs:
            id = [idx for idx, (resid, cid) in chain_mapping_onto_structure.items() if cid == chain_id]
            chains.append(ca.universe.atoms[id].residues)

        # TODO: check for mismatches

    else:
        print("The number of residues in the reference file, ", len(protein_from_file),
            " does not agree with the number of residues in the trajectory, ", len(ca),
            ". Will ignore the reference file and assign chainIDs based on sequence breaks.")

        chains, chain_mapping_onto_structure = assign_chains_from_breaks(ca)

    return chains, chain_mapping_onto_structure

def identify_molecules(chains):

    # TODO: Update this function to make use of get_residue_info to avoid silent failure for more than five chains.

    # WARNING: This heuristic might not work on all data formats!
    # WARNING: This assumes pMHC-TCR systems consists of 5 chains!

    # Identify peptide as the shortest chain
    chains_sorted = sorted(chains, key=lambda chain: len(chain))
    peptide = chains_sorted[0]

    # Remove peptide from the chain list
    remaining = [c for c in chains if c != peptide]

    # Identify MHC and TCR based on the order they are presented in the PDB file
    MHC = remaining[0:2]
    TCR = remaining[2:4]

    return [peptide, MHC, TCR]

def parse_input():
    parser = argparse.ArgumentParser(
        description="Analyze peptide–MHC-TCR interactions "
                    "from an MD trajectory."
    )
    parser.add_argument("-s", "--topology", required=True,
                        help="Topology/coordinate file (.gro, .tpr, .pdb)")
    parser.add_argument("-f", "--trajectory", required=True,
                        help="Trajectory file (.xtc, .trr, .dcd)")
    parser.add_argument("-r", "--reference", required=True,
                        help="Structure file with chain IDs, e.g. the PDB used "
                             "to set up the simulation")
    parser.add_argument("-co", "--contact-output", default="contacts.csv",
                        help="Output CSV file with contact probabilities (default: %(default)s)")

    # TODO: We can take e.g. cutoff distance or plotting as input as well

    return parser.parse_args()

def write_CSV(filename, datasets, chain_map):

    fieldnames = ["mol1", "resid1", "resname1", "chain1", "mol2", "resid2", "resname2", "chain2", "P_contact"]

    rows = []
    for dataset in datasets:
        data_mol1 = get_residue_info(dataset.group1, chain_map)
        data_mol2 = get_residue_info(dataset.group2, chain_map)

        residues1 = list(dataset.group1.residues)
        residues2 = list(dataset.group2.residues)

        # We only output data points with non-zero probabilities
        for i, j in np.argwhere(dataset.contactMap > 0.0):
            resid1, resname1, chain1, = data_mol1[residues1[i].resindex]
            resid2, resname2, chain2, = data_mol2[residues2[j].resindex]

            rows.append({
                        "mol1": dataset.mol1,
                        "resid1": resid1, "resname1": resname1, "chain1": chain1,
                        "mol2": dataset.mol2,
                        "resid2": resid2, "resname2": resname2, "chain2": chain2,
                        "P_contact": round(float(dataset.contactMap[i,j]), 4),
                    })

    # Sort the rows according to most probable contact
    rows.sort(key=lambda r: (-r["P_contact"]))

    # Write the CSV file
    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=["mol1", "resid1", "resname1", "chain1", "mol2", "resid2", "resname2", "chain2", "P_contact"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} contact pairs to {filename}")

    return

# Take the input from the command line
args = parse_input()

topology = args.topology
trajectory = args.trajectory
md_input = args.reference
contacts_filename = args.contact_output

# For testing:
#topology = "/home/cathrine/Projects/GANANA_3.10_immunology_workflow/Data/2NX5_2_original/REP3/2NX5_2_md_rep3.gro"
#trajectory = "/home/cathrine/Projects/GANANA_3.10_immunology_workflow/Data/2NX5_2_original/REP3/2NX5_2_md_rep3.xtc"
# We need the input file used to create the MD simulation files in order to keep track of chain IDs
#md_input = "/home/cathrine/Projects/GANANA_3.10_immunology_workflow/Data/2NX5_2_original/prep/2NX5_2_nowater.pdb"

ContactDataset = namedtuple("ContactDataset", "mol1 group1 mol2 group2 contactMap")

u = mda.Universe(topology, trajectory)

# Split protein into chains since this information is lost in the GRO file
protein = u.select_atoms("protein")
ca = protein.select_atoms("name CA")

# Identify the different molecules (peptide, MHC, TCR)
#ordered_molecules = identify_molecules_from_breaks(distances)
#ordered_molecules = assign_chains_from_file(ca, md_input)
chains, chain_map = assign_chains_from_file(ca, md_input)
ordered_molecules = identify_molecules(chains)

# Convert the ResidueGroup into an AtomGroup
peptide = ordered_molecules[0].atoms
MHC = sum([mol.atoms for mol in ordered_molecules[1]], mda.AtomGroup([], u))
TCR = sum([mol.atoms for mol in ordered_molecules[2]], mda.AtomGroup([], u))

# Calculate the closest atoms to the peptide, contacts are re-evaluated every frame
# We use this to avoid calculating too many contacts in the trajectory
MHC_peptide_contacts = (MHC + peptide).select_atoms("byres around 6 group peptide", peptide=peptide, updating=True, periodic=True)
TCR_peptide_contacts = (TCR + peptide).select_atoms("byres around 6 group peptide", peptide=peptide, updating=True, periodic=True)

# Map PDB residue numbers to global residue indices (needed when updating=True)
peptide_residue_mapping = create_global_residue_map(peptide)
MHC_residue_mapping = create_global_residue_map(MHC)
TCR_residue_mapping = create_global_residue_map(TCR)

# Function calls
cmap_avg_MHC = np.zeros((len(peptide.residues), len(MHC.residues)))
cmap_avg_TCR = np.zeros((len(peptide.residues), len(TCR.residues)))

for ts in u.trajectory:
    # Compute the box dimension for each ts since it might fluctuate during a NPT simulation
    cmap_avg_MHC = compute_contact_matrix(cmap_avg_MHC, peptide, MHC_peptide_contacts, peptide_residue_mapping, MHC_residue_mapping, box=ts.dimensions)
    cmap_avg_TCR = compute_contact_matrix(cmap_avg_TCR, peptide, TCR_peptide_contacts, peptide_residue_mapping, TCR_residue_mapping, box=ts.dimensions)
    #print(len(MHC_peptide_contacts.residues))

cmap_avg_MHC /= len(u.trajectory)
cmap_avg_TCR /= len(u.trajectory)

# Visualize the contact map (good for testing)
visualize_contact_map(cmap_avg_MHC, cmap_avg_TCR, peptide, MHC, TCR, chain_map)

# Write contact maps to a CSV file
write_CSV(contacts_filename, [ContactDataset("peptide", peptide, "MHC", MHC, cmap_avg_MHC), ContactDataset("peptide", peptide, "TCR", TCR, cmap_avg_TCR)], chain_map)

# TODO: plot MHC-TCR contacts as well?
# TODO: remove hard-coded numbers
# TODO: current contact maps include hydrogen atoms, exclude these to the speed calculations
