help([[
GSI build and runtime environment
Machine: NOAA Ursa
Compiler: Intel OneAPI
]])

whatis("Name: ursa_intel_gsi")
whatis("Machine: NOAA Ursa")
whatis("Compiler: Intel OneAPI")
whatis("Application: GSI")

-- Helper functions
local function required_env(name)
    local value = os.getenv(name)

    if not value or value == "" then
        LmodError(name .. " is not defined")
    end

    return value
end

local function discover_prefix(command, name)
    local prefix = capture(command .. " 2>/dev/null")
    prefix = prefix:gsub("%s+$", "")

    if prefix == "" then
        LmodError("Unable to discover " .. name .. " prefix")
    end

    return prefix
end

-- Compiler and MPI
depends_on("intel-oneapi-compilers/" ..
    required_env("COMPILER_VERSION"))

depends_on("intel-oneapi-mpi/" ..
    required_env("MPI_VERSION"))

-- Build dependencies
depends_on("cmake/" .. required_env("CMAKE_VERSION"))

depends_on("netcdf-c/" ..
    required_env("NETCDF_C_VERSION"))

depends_on("netcdf-fortran/" ..
    required_env("NETCDF_FORTRAN_VERSION"))

depends_on("hdf5/" .. required_env("HDF5_VERSION"))

depends_on("parallel-netcdf/" ..
    required_env("PNETCDF_VERSION"))

depends_on("libtirpc/" ..
    required_env("LIBTIRPC_VERSION"))

-- Intel MKL
depends_on("intel-oneapi-mkl")

-- Discover NetCDF installation prefixes
local netcdf_c = discover_prefix("nc-config --prefix", "NetCDF-C")
local netcdf_fortran = discover_prefix("nf-config --prefix", "NetCDF-Fortran")

-- Export NetCDF paths
setenv("NETCDF", netcdf_c)
setenv("NETCDF_C", netcdf_c)
setenv("NETCDF_FORTRAN", netcdf_fortran)

-- MPI
local mpi_root = required_env("I_MPI_ROOT")
setenv("MPI_ROOT", mpi_root)

-- MKL
local mkl_root = required_env("MKLROOT")
setenv("LAPACK_PATH", pathJoin(mkl_root, "lib/intel64"))

-- libtirpc
local tirpc_root = required_env("LIBTIRPC_ROOT")

setenv("LIBTIRPC_DIR", tirpc_root)
setenv("LIBTIRPC_INC", pathJoin(tirpc_root, "include/tirpc"))
setenv("LIBTIRPC_LIB", pathJoin(tirpc_root, "lib"))

-- Application paths
setenv("WRF_DIR", required_env("WRF_DIR"))
setenv("GSI_ROOT", required_env("GSI_ROOT"))

-- Build identification
setenv("MACHINE", "ursa")
setenv("COMPILER", "intel")
setenv("COMPONENT", "gsi")

