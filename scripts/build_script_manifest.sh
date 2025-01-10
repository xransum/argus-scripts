#!/bin/bash
# Generates script manifest.

CURR_ROOT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT_DIR="$(dirname "$CURR_ROOT_DIR")"
SCRIPTS_REL_PATH="src"
SCRIPTS_ROOT_DIR="${REPO_ROOT_DIR}/${SCRIPTS_REL_PATH}"
MANIFEST_NAME="scripts_manifest.txt"
MANIFEST_PATH="${REPO_ROOT_DIR}/${MANIFEST_NAME}"
MANIFEST_HEADER="""# File: ${MANIFEST_NAME}
# Generated on: $(date '+%Y-%m-%d')
"""

if [ ! -d "$SCRIPTS_ROOT_DIR" ]; then
    echo "Failed to find the scripts source dir ${SCRIPTS_ROOT_DIR}"
    exit 1
fi

scripts_manifest="${MANIFEST_HEADER}\n"
for script in $(find "$SCRIPTS_ROOT_DIR" -type f -executable); do
    file_name="$(basename "$script")"
    rel_path="${SCRIPTS_REL_PATH}/${file_name}"
    scripts_manifest="${scripts_manifest}${rel_path}\n"
done


echo "Writting script manifest: ${MANIFEST_PATH}"
echo -e "$scripts_manifest" > "${MANIFEST_PATH}"
echo "Done!"