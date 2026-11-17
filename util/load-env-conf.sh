#!/bin/bash
#
# WoFS Environment Loader
#
# Usage:
#   source util/load-env.sh <machine> <compiler> <application>
#
# Example:
#   source util/load-env.sh ursa intel gsi
#
# Configuration:
#   config/ursa_intel_gsi.conf
#
# Modulefile:
#   modulefiles/ursa_intel_gsi.lua
#

# ============================================================
# 1. Ensure the script is sourced
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced."
    echo "Usage: source util/load-env.sh ursa intel gsi"
    exit 1
fi

# ============================================================
# 2. Determine project root
# ============================================================

UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${UTIL_DIR}/.." && pwd)"

# ============================================================
# 3. Read arguments
# ============================================================

MACHINE="${1:-}"
COMPILER="${2:-}"
COMPONENT="${3:-}"

if [[ -z "${MACHINE}" || -z "${COMPILER}" || -z "${COMPONENT}" ]]; then
    echo "ERROR: Missing environment arguments."
    echo ""
    echo "Usage:"
    echo "  source util/load-env.sh <machine> <compiler> <application>"
    echo ""
    echo "Example:"
    echo "  source util/load-env.sh ursa intel gsi"
    return 1
fi

# Construct environment identifier
ENV_NAME="${MACHINE}_${COMPILER}_${COMPONENT}"

CONFIG_FILE="${PROJECT_ROOT}/config/${ENV_NAME}.conf"
MODULE_FILE="${PROJECT_ROOT}/modulefiles/${ENV_NAME}.lua"

# ============================================================
# 4. Validate configuration and modulefile
# ============================================================

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Configuration file not found:"
    echo "  ${CONFIG_FILE}"
    return 1
fi

if [[ ! -f "${MODULE_FILE}" ]]; then
    echo "ERROR: Modulefile not found:"
    echo "  ${MODULE_FILE}"
    return 1
fi

# ============================================================
# 5. Load configuration
# ============================================================

echo "================================================"
echo " Loading WoFS environment"
echo "================================================"

source "${CONFIG_FILE}"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to load configuration."
    return 1
fi

# ============================================================
# 6. Reset module environment
# ============================================================

module purge

if [[ $? -ne 0 ]]; then
    echo "ERROR: module purge failed."
    return 1
fi

# ============================================================
# 7. Register project modulefiles
# ============================================================

module use "${PROJECT_ROOT}/modulefiles"

# ============================================================
# 8. Load selected environment
# ============================================================

module load "${ENV_NAME}"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to load ${ENV_NAME}"
    return 1
fi

# ============================================================
# 9. Display environment information
# ============================================================

echo ""
echo "================================================"
echo " WoFS Environment Successfully Loaded"
echo "================================================"
echo " Machine    : ${MACHINE}"
echo " Compiler   : ${COMPILER}"
echo " Application: ${COMPONENT}"
echo " Environment: ${ENV_NAME}"
echo " Config     : ${CONFIG_FILE}"
echo " Modulefile : ${MODULE_FILE}"
echo "================================================"

return 0

