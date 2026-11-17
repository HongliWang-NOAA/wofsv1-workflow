#!/bin/bash
#
# WoFS environment loader
#
# Usage:
#   source util/load-env.sh gsi
#

# Determine project root
UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${UTIL_DIR}/.." && pwd)"

# Select component
COMPONENT="${1:-gsi}"

VERSION_FILE="${PROJECT_ROOT}/versions/${COMPONENT}.ver"
MODULE_NAME="ursa_intel_${COMPONENT}"

# Check configuration
if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "ERROR: Version file not found: ${VERSION_FILE}"
    return 1
fi

# Load version configuration
source "${VERSION_FILE}"

# Reset environment
module purge

# Add project modulefiles directory
module use "${PROJECT_ROOT}/modulefiles"

# Load complete environment
module load "${MODULE_NAME}"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to load ${MODULE_NAME}"
    return 1
fi

echo "================================================"
echo " WoFS Environment Successfully Loaded"
echo " Component : ${COMPONENT}"
echo " Compiler  : ${COMPILER} ${COMPILER_VERSION}"
echo " MPI       : ${MPI} ${MPI_VERSION}"
echo " GSI_ROOT  : ${GSI_ROOT}"
echo " WRF_DIR   : ${WRF_DIR}"
echo "================================================"

