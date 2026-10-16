#!/bin/bash

# ============================================================
# Docking script for multiple proteins vs multiple ligands in a library
# All files are located under the directory "PDBQT"
# Output directories: docked_<protein>-<plant> inside PDBQT
# ============================================================

# --- Configuration ---
BASE_DIR="PDBQT"                     # Base directory containing all files
# A variable PROTEINS is defined to hold the names of the protein files (without extensions) that will be used in the docking process. Each protein name corresponds to a receptor file and a configuration file that should exist in the BASE_DIR. The script will loop through each protein and each plant ligand directory to perform docking using AutoDock Vina.
PROTEINS=("abbd" "abcd")               # Protein base names (replace with yours)
# A variable PLANTS is defined to hold the names of the plant ligand directories that will be used in the docking process. Each plant name corresponds to a directory containing ligand files in PDBQT format. The script will loop through each protein and each plant ligand directory to perform docking using AutoDock Vina.
PLANTS=("prepped-mango" "prepped-carrot" "prepped_Chromolaena-Odorata")   # Plant folders
CPU=8                                   # Number of CPU cores for Vina

# --- Check if base directory exists ---
if [[ ! -d "$BASE_DIR" ]]; then
    echo "ERROR: Base directory '$BASE_DIR' does not exist."
    exit 1
fi

cd "$BASE_DIR" || exit 1

echo "Starting docking in $(pwd)"
echo "Proteins: ${PROTEINS[*]}"
echo "Plants:   ${PLANTS[*]}"
echo "----------------------------------------"

# --- Loop over each protein ---
for protein in "${PROTEINS[@]}"; do
    receptor="${protein}.receptor.pdbqt"
    config="${protein}.conf"

    # Verify receptor and config files exist
    if [[ ! -f "$receptor" ]]; then
        echo "WARNING: Receptor file '$receptor' not found. Skipping protein '$protein'."
        continue
    fi
    if [[ ! -f "$config" ]]; then
        echo "WARNING: Config file '$config' not found. Skipping protein '$protein'."
        continue
    fi

    # --- Loop over each plant ---
    for plant in "${PLANTS[@]}"; do
        ligand_dir="$plant"
        output_dir="docked_${protein}-${plant}"

        # Check if plant ligand directory exists
        if [[ ! -d "$ligand_dir" ]]; then
            echo "WARNING: Ligand directory '$ligand_dir' not found. Skipping $plant for $protein."
            continue
        fi

        # Create output directory (if it doesn't exist)
        mkdir -pv "$output_dir"

        # Count ligand files
        shopt -s nullglob
        ligand_files=("$ligand_dir"/*.pdbqt)
        shopt -u nullglob

        if [[ ${#ligand_files[@]} -eq 0 ]]; then
            echo "No .pdbqt files found in '$ligand_dir'. Skipping $plant for $protein."
            continue
        fi

        echo "Processing protein '$protein' with plant '$plant' (${#ligand_files[@]} ligands)..."

        # --- Loop over each ligand in the plant folder ---
        for ligand in "${ligand_files[@]}"; do
            ligand_name=$(basename "$ligand")
            output_file="$output_dir/$ligand_name"

            echo "  Docking $ligand_name ..."

            # Run Vina
            vina --receptor $receptor --config $config --ligand $ligand --out "$output_file" --cpu "$CPU"

            # Check if docking succeeded
            if [[ $? -eq 0 ]]; then
                echo "    Finished: $output_file"
            else
                echo "    ERROR: Vina failed for $ligand_name" >&2
            fi
        done
    done
done

echo "----------------------------------------"
echo "All docking runs completed. Results are in '$BASE_DIR'."
