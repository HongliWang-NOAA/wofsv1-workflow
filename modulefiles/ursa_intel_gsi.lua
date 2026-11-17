help([[
GSI build and runtime environment
Machine: NOAA Ursa
Compiler: Intel OneAPI
]])

whatis("Name: ursa_intel_gsi")
whatis("Machine: NOAA Ursa")
whatis("Compiler: Intel OneAPI")
whatis("Application: GSI")

-- Compiler
depends_on(
    "intel-oneapi-compilers/" ..
    os.getenv("COMPILER_VERSION")
)

-- MPI
depends_on(
    "intel-oneapi-mpi/" ..
    os.getenv("MPI_VERSION")
)

-- Build tools and libraries
depends_on("cmake/" .. os.getenv("CMAKE_VERSION"))
depends_on("netcdf-c/" .. os.getenv("NETCDF_C_VERSION"))
depends_on("netcdf-fortran/" .. os.getenv("NETCDF_FORTRAN_VERSION"))
depends_on("hdf5/" .. os.getenv("HDF5_VERSION"))
depends_on("parallel-netcdf/" .. os.getenv("PNETCDF_VERSION"))
depends_on("libtirpc/" .. os.getenv("LIBTIRPC_VERSION"))

-- MKL
depends_on("intel-oneapi-mkl")

-- NetCDF
local netcdf = os.getenv("NETCDF_ROOT")

if not netcdf or netcdf == "" then
    LmodError("NETCDF_ROOT is not defined")
end

setenv("NETCDF", netcdf)
setenv("NETCDF_C", netcdf)
setenv("NETCDF_FORTRAN", netcdf)

prepend_path("PATH", netcdf .. "/bin")
prepend_path("LD_LIBRARY_PATH", netcdf .. "/lib")
prepend_path("LIBRARY_PATH", netcdf .. "/lib")
prepend_path("CPATH", netcdf .. "/include")

-- MPI
setenv("MPI_ROOT", os.getenv("I_MPI_ROOT"))

-- MKL
setenv("LAPACK_PATH",
       os.getenv("MKLROOT") .. "/lib/intel64")

-- libtirpc
local tirpc_root = os.getenv("LIBTIRPC_ROOT")

if not tirpc_root or tirpc_root == "" then
    LmodError("LIBTIRPC_ROOT is not defined after loading libtirpc")
end

setenv("LIBTIRPC_DIR", tirpc_root)
setenv("LIBTIRPC_INC", pathJoin(tirpc_root, "include/tirpc"))
setenv("LIBTIRPC_LIB", pathJoin(tirpc_root, "lib"))

-- Application paths
setenv("WRF_DIR", os.getenv("WRF_DIR"))
setenv("GSI_ROOT", os.getenv("GSI_ROOT"))

setenv("MACHINE", "ursa")
setenv("COMPILER", "intel")
setenv("COMPONENT", "gsi")
