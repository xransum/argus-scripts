#!/bin/bash
# Generates script manifest.

CURR_ROOT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT_DIR="$(dirname "$CURR_ROOT_DIR")"
SCRIPTS_REL_PATH="src"
SCRIPTS_ROOT_DIR="${REPO_ROOT_DIR}/${SCRIPTS_REL_PATH}"
MANIFEST_NAME="scripts_manifest.txt"
MANIFEST_PATH="${REPO_ROOT_DIR}/${MANIFEST_NAME}"
MANIFEST_HEADER="# File: ${MANIFEST_NAME}
# Generated on: $(date '+%Y-%m-%d')"

if [ ! -d "$SCRIPTS_ROOT_DIR" ]; then
    echo "Failed to find the scripts source dir ${SCRIPTS_ROOT_DIR}"
    exit 1
fi

scripts_manifest="${MANIFEST_HEADER}\n"
temp_manifest=$(mktemp)
find "$SCRIPTS_ROOT_DIR" -type f -executable -print0 | while IFS= read -r -d '' script; do
    file_name="$(basename "$script")"
    rel_path="${SCRIPTS_REL_PATH}/${file_name}"
    echo "${rel_path}" >>"$temp_manifest"
done

while IFS= read -r line; do
    scripts_manifest="${scripts_manifest}${line}\n"
done <"$temp_manifest"
rm "$temp_manifest"

echo "Writting script manifest: ${MANIFEST_PATH}"
echo -e "$scripts_manifest" >"${MANIFEST_PATH}"
echo "Done!"
