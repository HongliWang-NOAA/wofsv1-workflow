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
    required_env("compiler_version"))

depends_on("intel-oneapi-mpi/" ..
    required_env("mpi_version"))

-- Build dependencies
depends_on("cmake/" .. required_env("cmake_version"))

depends_on("netcdf-c/" ..
    required_env("netcdf_c_version"))

depends_on("netcdf-fortran/" ..
    required_env("netcdf_fortran_version"))

depends_on("hdf5/" .. required_env("hdf5_version"))

depends_on("parallel-netcdf/" ..
    required_env("pnetcdf_version"))

depends_on("libtirpc/" ..
    required_env("libtirpc_version"))

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
setenv("WRF_DIR", required_env("wrf_dir"))
-- setenv("GSI_ROOT", required_env("gsi_root"))

-- Build identification
setenv("MACHINE", "ursa")
setenv("COMPILER", "intel")
setenv("COMPONENT", "gsi")

