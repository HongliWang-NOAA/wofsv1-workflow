#!/bin/bash
#SBATCH -J run_gsi_mem
#SBATCH -o run_gsi.log
#SBATCH -e run_gsi.err
#SBATCH -p u1-compute
#SBATCH -q debug
#SBATCH --mem=300G
#SBATCH -n 2 
#SBATCH -t 00:4:00

###############################################################################
# Load modules
###############################################################################

module purge

module load intel-oneapi-compilers/2023.2.0
module load intel-oneapi-mpi/2021.13.1
module load intel-oneapi-mkl/2024.2.1
module load hdf5/1.14.3
module load netcdf-c/4.9.2
module load netcdf-fortran/4.6.1

###############################################################################
# Debugging
###############################################################################

set -x
export PS4='+ ${BASH_SOURCE}:${LINENO}: '
set -e

###############################################################################
# WoFS GSI OBSERVER - Developer driver
###############################################################################

# Workflow installation
export HOMEwofs="/scratch4/NCEPDEV/fv3-cam/Hongli.Wang/WoFS/workflow/wofsv1-workflow"
export EXECwofs="${HOMEwofs}/exe"
export FIXwofs="${HOMEwofs}/fix"
export PARMwofs="${HOMEwofs}/parm"
export USHwofs="${HOMEwofs}/ush"

# CRTM coefficients
export FIXcrtm="${CRTM_FIX:-${HOMEwofs}/fix/crtm_coeffs_2.2.3}"

###############################################################################
# Run configuration
###############################################################################

export RUN_ENVIR=developer
export SENDECF=NO
export SENDCOM=NO
export SENDDBN=NO

export NET=wofs
export RUN=wofs
export model=wofs
export wofs_ver=v1

# Analysis cycle
export PDY=${PDY:-20260727}
export cyc=${cyc:-10}
export subcyc=${subcyc:-00}  # minutes
# Ensemble member
## 0000 = ensemble mean
# 1-36 = ensemble members
export ensmem=${ensmem:-1}
export dom=wofs

# Environment
export envir=para
export userid=${USER}

###############################################################################
# Input and output directories
###############################################################################

# WoFS ensemble background
export WOFSGES="/scratch4/NCEPDEV/stmp/Hongli.Wang/wofs/realtime/20260727/enkfdir"

# Observation input directories
export COMINobsproc="/scratch4/NCEPDEV/stmp/Hongli.Wang/wofs_wrf/wrf/obs/WOFSRun20260727-133106d1"
export PREPDIR2="/scratch4/NCEPDEV/fv3-cam/Hongli.Wang/retro/obs/conv/obs_rap"

#export COMINobsproc="${COMINobsproc:-/path/to/obsproc}"
#export PREPDIR2="${PREPDIR2:-/path/to/wofs/observation/input}"

# Input directory containing WoFS analysis files
export COMIN="/scratch4/NCEPDEV/stmp/Hongli.Wang/wofs/realtime/20260727/enkfdir/"
#export COMIN="${COMIN:-/path/to/wofs/com/${PDY}/wofs}"

# Output directory for GSI diagnostics
export COMOUT="${COMOUT:-${HOMEwofs}/test/gsi_output/${PDY}/${cyc}/${subcyc}}"

# GSI working directory
export DATAROOT="${DATAROOT:-${HOMEwofs}/test/gsi_work}"

mkdir -p "${COMOUT}" "${DATAROOT}"

###############################################################################
# Additional environment variables
###############################################################################

#export WOFSGES_ENKF="${WOFSGES}"
#export WOFSGES_SFC="${WOFSGES}"

#export KMP_STACKSIZE=1024m
#export OMP_STACKSIZE=500M
#export OMP_NUM_THREADS=2

# Prevent operational notification and database calls
export SENDECF=NO
export SENDCOM=NO
export SENDDBN=NO

###############################################################################
# Logging
###############################################################################

#jlogfile is input to postmsg command which is not available on Ursa
#export jlogfile="${COMOUT}/gsi_observer_${PDY}${cyc}${subcyc}_mem$(printf '%04d' ${ensmem}).log"

export pgmout="OUTPUT.gsi_observer"

echo "======================================================"
echo "WoFS GSI OBSERVER"
echo "======================================================"
echo "PDY       = ${PDY}"
echo "Cycle     = ${cyc}"
echo "Member    = ${ensmem}"
echo "WOFSGES   = ${WOFSGES}"
echo "COMIN     = ${COMIN}"
echo "COMOUT    = ${COMOUT}"
echo "DATAROOT  = ${DATAROOT}"
echo "======================================================"

###############################################################################
# Check required input directories
###############################################################################

for dir in "${HOMEwofs}" "${EXECwofs}" "${FIXwofs}" \
           "${PARMwofs}" "${WOFSGES}" "${COMIN}"; do
    if [[ ! -d "${dir}" ]]; then
        echo "ERROR: Required directory does not exist: ${dir}"
        exit 1
    fi
done

if [[ ! -x "${EXECwofs}/wofs_gsi" ]]; then
    echo "ERROR: Missing GSI executable: ${EXECwofs}/wofs_gsi"
    exit 1
fi

#if [[ ! -x "${EXECwofs}/wofs_write_idate" ]]; then
#    echo "ERROR: Missing executable: ${EXECwofs}/wofs_write_idate"
#    exit 1
#fi

if [[ ! -d "${FIXcrtm}" ]]; then
    echo "ERROR: CRTM directory does not exist: ${FIXcrtm}"
    exit 1
fi

###############################################################################
# Run JWOFS_GSI_OBSERVER
###############################################################################

JOB="${HOMEwofs}/jobs/JWOFS_GSI_OBSERVER"

if [[ ! -f "${JOB}" ]]; then
    echo "ERROR: Job script does not exist: ${JOB}"
    exit 1
fi

chmod +x "${JOB}"

echo "Starting JWOFS_GSI_OBSERVER ..."

"${JOB}"

rc=$?

if [[ ${rc} -ne 0 ]]; then
    echo "ERROR: JWOFS_GSI_OBSERVER failed with status ${rc}"
    exit ${rc}
fi

echo "======================================================"
echo "WoFS GSI OBSERVER completed successfully"
echo "======================================================"

