#!/bin/ksh -l
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:       exwofs_analysis_sh.sms
# Script description:  runs the GSI observer for EnKF 
#
# Author:   Ming Hu / Geoff Manikin / Julia Zhu  Org: EMC       Date: 2011-10-01
#
# Script history log:
# 2014-08-01  C Alexander / M Hu / G Manikin / J Yang - HRRRv1
# 2016-02-05  C Alexander / G Manikin -  HRRRv2 
# 2018-01-24  B Blake / G Manikin / C Alexander - HRRRv3
# 2026-11-18  H Wang Adapt to WoFSv1 

ulimit -s 512000
set -x

# Set paths to unix commands
DATE=/bin/date
#AWK="/bin/awk --posix"

# Create the working directory and cd into it
cd ${DATA}

# Set up some environment variables
export ATP_ENABLED=0
export MALLOC_MMAP_MAX=0
export MALLOC_TRIM_THRESHOLD_=134217728
export OMP_STACKSIZE=500M
export KMP_STACKSIZE=1024m
export OMP_NUM_THREADS=2

# Set to yes for faster collective ops (mpi reduce)
# but may not yield bitwise identical results from
# run to run when yes.
export MP_COLLECTIVE_OFFLOAD=yes

# create dirctory for member
echo "run gsi observer for member =",$ensmem
#ensmemid=`printf %4.4i $ensmem`
ensmemid=$ensmem

if [ $ensmem -eq 00 ]; then
#  rm -rf mean
  mkdir mean
  cd mean
else
#  rm -rf mem${ensmemid}
  mkdir -p mem${ensmemid}
  cd mem${ensmemid}
fi

# Make sure START_TIME is in the correct format
#START_TIME=${PDY}' '${cyc}
#echo $START_TIME
#echo $cyc
#START_TIME=`echo "${START_TIME}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/'`
#START_TIME=`${DATE} -d "${START_TIME}"`

# Analysis date and time
# PDY    = YYYYMMDD
# cyc    = HH
# subcyc = MM

cyc=$(printf "%02d" "${cyc}")
subcyc=${subcyc:-00}
subcyc=$(printf "%02d" "${subcyc}")

# Construct analysis time
START_TIME="${PDY} ${cyc}:${subcyc}"

echo "PDY       = ${PDY}"
echo "cyc       = ${cyc}"
echo "subcyc    = ${subcyc}"
echo "START_TIME= ${START_TIME}"

# Convert to system date
START_TIME=$(${DATE} -d "${START_TIME}" "+%Y-%m-%d %H:%M:%S")

echo "Final START_TIME = ${START_TIME}"

# produce binary date file, needed for radar diag files
#ANALYSIS_TIME=`${DATE} "+%Y%m%d%H" -d "${START_TIME}"`
ANALYSIS_TIME=$(${DATE} "+%Y%m%d%H%M" -d "${START_TIME}")
echo ${ANALYSIS_TIME} > idate.input
#WRITE_IDATE=${EXECwofs}/wofs_write_idate
#if [ ! -x "${WRITE_IDATE}" ]; then
#  errmsg="ERROR: ${WRITE_IDATE} does not exist!"
#  err_exit $errmsg
#fi
#cp ${WRITE_IDATE} wofs_write_idate
#runline="mpiexec -n 1 -ppn 1 ./wofs_write_idate"
#$runline >> $DATA/${pgmout}_date 2>errfile
#export err=$?; err_chk


# Bring over background field (it's modified by GSI so we can't link to it)
time_str=`${DATE} "+%Y-%m-%d_%H_%M_%S" -d "${START_TIME}"`
echo " time_str = ${time_str}"

timestr15m=`${DATE} +%Y%m%d%H%M -d "${START_TIME} 15 minutes ago"`
# Look for background from pre-forecast background
if [ $ensmem -eq 00 ]; then
   bkfile=${WOFSGES}/wofs_d01_${timestr15m}f01_mem0001
   inputfile=${COMIN}/wofs.t${cyc}z.wrfinput_d01.mean
else
#wrfinput_d01.9
   #bkfile=${WOFSGES}/wofs_d01_${timestr15m}f01_mem${ensmemid}
   bkfile=${WOFSGES}/wrfinput_d01.${ensmemid}
   inputfile=${COMIN}/wofs.t${cyc}z.wrfinput_d01.mem${ensmemid}
fi
if [ -r ${bkfile} ]; then
  echo " GSI background run using ${bkfile}"
  cp -p ${bkfile} ${inputfile}
  ln -sf ${inputfile} ./wrf_inout
# calculate ensemble mean
#  if [ $ensmem -eq 00 ]; then
#     cp ${EXECwofs}/wofs_cal_ensmean . 
#     ln -sf ${WOFSGES}/wofs_d01_${timestr15m}f01_mem00?? .
#     #runline="mpiexec -n 48 -ppn 48 --cpu-bind core --depth 2 /usr/bin/env OMP_NUM_THREADS=2 ./wofs_cal_ensmean 2 ./ wrf_inout_d01 wofs_d01_${timestr15m}f01_mem0 36"
#     $runline
#  fi
# No background available so abort
else
  echo "${bkfile} does not exist!!"
  if [ ${cyc} -eq 09 -o ${cyc} -eq 21 ]; then
     echo "Wanring: skip GSI for cold start" > ${COMOUT}/diagdone${cyc}00.${ensmemid}
     exit 0
  fi
  #errmsg="FATAL ERROR: No background file for analysis at ${time_run}!!!!"
  errmsg="FATAL ERROR: No background file for analysis at ${time_str} !!!!"
  echo $errmsg
  echo " FATAL ERROR: Cycle ${PDY}${cyc}: GSI failed because of no background" 
  err_exit $errmsg
fi

#  need to use the "early" data at 00/12z since the regular RAP dumps
#     occur later at these times
if [ ${cyc} -eq 00 -o ${cyc} -eq 12 ]; then
  PREPBUFR=${COMINobsproc}/rap_e.${PDY}
  prepsuffix=rap_e
else
  PREPBUFR=${COMINobsproc}/rap.${PDY}
  prepsuffix=rap
fi

# prepbufr section
if [ -r "${PREPBUFR}/${prepsuffix}.t${cyc}z.prepbufr.tm00" ]; then
 cp ${PREPBUFR}/${prepsuffix}.t${cyc}z.prepbufr.tm00 .
 mv ${prepsuffix}.t${cyc}z.prepbufr.tm00 newgblav.${PDY}.rap.t${cyc}z.prepbufr
 ln -sf newgblav.${PDY}.rap.t${cyc}z.prepbufr ./prepbufr
else
 echo "Warning: ${PREPBUFR}/${prepsuffix}.t${cyc}z.prepbufr.tm00 does not exist!"
fi

# ----------------------------------------------------------------------
# DBZ observations
# ----------------------------------------------------------------------
#/scratch4/NCEPDEV/stmp/Hongli.Wang/wofs_wrf/wrf/obs/WOFSRun20260727-133106d1/202607270915/0915-dbzobs.nc
echo "PDY = ${PDY}"
if [[ -e "${COMINobsproc}/${PDY}${cyc}${subcyc}/${cyc}${subcyc}-dbzobs.nc" ]]; then

    /bin/cp -pv "${COMINobsproc}/${PDY}${cyc}${subcyc}/${cyc}${subcyc}-dbzobs.nc" \
        "./dbzobs.nc"
else
    echo "WARNING: DBZ file not found for ${timestr}"
exit 1
fi

ls -lrt 
# Link to binary radar data
obsfile=${PREPDIR2}/wofs.t${cyc}z.NSSLRefInGSI_d01.bufr
if [ -r "${obsfile}" ]; then
  ln -sf ${obsfile} ./refInGSI
else
  echo "Warning: ${obsfile} does not exist!"
fi

obsfile=${PREPDIR2}/wofs.t${cyc}z.Gridded_ref_d01.nc
if [ -r "${obsfile}" ]; then
  ln -sf ${obsfile} ./dbzobs.nc
else
  echo "Warning: ${obsfile} does not exist!"
fi

obsfile=${PREPDIR2}/wofs.t${cyc}z.NASALaRCCloudInGSI_d01.bufr
if [ -r "${obsfile}" ]; then
  ln -sf ${obsfile} ./larcInGSI
else
  echo "Warning: ${obsfile} does not exist!"
fi

# add radial velocity data
if [ -r "${PREPBUFR}/${prepsuffix}.t${cyc}z.nexrad.tm00.bufr_d" ]; then
  ln -sf ${PREPBUFR}/${prepsuffix}.t${cyc}z.nexrad.tm00.bufr_d ./l2rwbufr
else
  echo "Warning: ${PREPBUFR}/${prepsuffix}.t${cyc}z.nexrad.tm00.bufr_d is not available"
fi

# add SATWND data
if [ -r "${PREPBUFR}/${prepsuffix}.t${cyc}z.satwnd.tm00.bufr_d" ]; then
  ln -sf ${PREPBUFR}/${prepsuffix}.t${cyc}z.satwnd.tm00.bufr_d ./satwndbufr
else
  echo "Warning: ${PREPBUFR}/${prepsuffix}.t${cyc}z.satwnd.tm00.bufr_d is not available"
fi

# Set fixed files
#   berror   = forecast model background error statistics
#   specoef  = CRTM spectral coefficients
#   trncoef  = CRTM transmittance coefficients
#   RTMEMIS = CRTM coefficients for IR sea surface emissivity model
#   aerocoef = CRTM coefficients for aerosol effects
#   cldcoef  = CRTM coefficients for cloud effects
#   satinfo  = text file with information about assimilation of brightness temperatures
#   satangl  = angle dependent bias correction file (fixed in time)
#   pcpinfo  = text file with information about assimilation of prepcipitation rates
#   ozinfo   = text file with information about assimilation of ozone data
#   errtable = text file with obs error for conventional data (regional only)
#   convinfo = text file with information about assimilation of conventional data
#   bufrtable= text file ONLY needed for single obs test (oneobstest=.true.)
#   bftab_sst= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)

anavinfo=${FIXwofs}/wofs_anavinfo.txt 
BERROR=${FIXwofs}/wofs_berror_stats
# SATANGL=${FIXwofs}/wofs_global_satangbias.txt
SATINFO=${FIXwofs}/wofs_satinfo

RTMAERO=${FIXcrtm}/AerosolCoeff.bin
RTMCLDS=${FIXcrtm}/CloudCoeff.bin
RTMEMIS_IRwater=${FIXcrtm}/Nalli.IRwater.EmisCoeff.bin
RTMEMIS_IRice=${FIXcrtm}/NPOESS.IRice.EmisCoeff.bin
RTMEMIS_IRland=${FIXcrtm}/NPOESS.IRland.EmisCoeff.bin
RTMEMIS_IRsnow=${FIXcrtm}/NPOESS.IRsnow.EmisCoeff.bin
RTMEMIS_VISice=${FIXcrtm}/NPOESS.VISice.EmisCoeff.bin
RTMEMIS_VISland=${FIXcrtm}/NPOESS.VISland.EmisCoeff.bin
RTMEMIS_VISsnow=${FIXcrtm}/NPOESS.VISsnow.EmisCoeff.bin
RTMEMIS_VISwater=${FIXcrtm}/NPOESS.VISwater.EmisCoeff.bin
RTMEMIS_MWwater=${FIXcrtm}/FASTEM5.MWwater.EmisCoeff.bin

CONVINFO=${FIXwofs}/wofs_convinfo.txt
#CONVINFO=${FIXwofs}/wofs_nam_regional_convinfo
OZINFO=${FIXwofs}/wofs_global_ozinfo.txt    
PCPINFO=${FIXwofs}/wofs_global_pcpinfo.txt

OBERROR=${FIXwofs}/wofs_errtable
#AIRCRAFTREJECTLIST=${FIXwofs}/wofs_current_bad_aircraft.txt   # aircraft reject list
#SURFACEUSELIST=${FIXwofs}/wofs_current_mesonet_uselist.txt # mesonet use list
#SURFACEPROVIDERLIST=${FIXwofs}/wofs_gsd_sfcobs_provider.txt # mesonet network use list

# Fixed fields
 cp $anavinfo anavinfo
 cp $BERROR   berror_stats
# cp $SATANGL  satbias_angle
 cp $SATINFO  satinfo
 cp $CONVINFO convinfo
 cp $OZINFO   ozinfo
 cp $PCPINFO  pcpinfo
 cp $OBERROR  errtable
# cp $AIRCRAFTREJECTLIST current_bad_aircraft
#cp $SURFACEUSELIST gsd_sfcobs_uselist.txt
# cp $SURFACEPROVIDERLIST gsd_sfcobs_provider.txt
 
#    # CRTM Spectral and Transmittance coefficients
ln -sf $RTMAERO  ./AerosolCoeff.bin
ln -sf $RTMCLDS  ./CloudCoeff.bin
ln -sf $RTMEMIS_IRwater ./Nalli.IRwater.EmisCoeff.bin
ln -sf $RTMEMIS_IRice ./NPOESS.IRice.EmisCoeff.bin
ln -sf $RTMEMIS_IRsnow ./NPOESS.IRsnow.EmisCoeff.bin
ln -sf $RTMEMIS_IRland ./NPOESS.IRland.EmisCoeff.bin
ln -sf $RTMEMIS_VISice ./NPOESS.VISice.EmisCoeff.bin
ln -sf $RTMEMIS_VISland ./NPOESS.VISland.EmisCoeff.bin
ln -sf $RTMEMIS_VISsnow ./NPOESS.VISsnow.EmisCoeff.bin
ln -sf $RTMEMIS_VISwater ./NPOESS.VISwater.EmisCoeff.bin
ln -sf $RTMEMIS_MWwater ./FASTEM5.MWwater.EmisCoeff.bin

for pattern in \
    "NPOESS.*" \
    "USGS.*" \
    "MWwaterLUT.bin" \
    "WuSmith.IRwater.EmisCoeff.bin" \
    "abi*"
do
    find "${FIXcrtm}" -maxdepth 1 -name "\${pattern}" \
        -exec /bin/ln -sf {} . \;
done

# Copy CRTM coefficient files based on entries in satinfo file
for file in `awk '{if($1!~"!"){print $1}}' ./satinfo | sort | uniq` ;do 
   ln -sf ${FIXcrtm}/${file}.SpcCoeff.bin ./
   ln -sf ${FIXcrtm}/${file}.TauCoeff.bin ./
done

# Only need this file for single obs test
 bufrtable=${PARMwofs}/wofs_prepobs_prep.bufrtable
 cp $bufrtable ./prepobs_prep.bufrtable

# Set some parameters for use by the GSI executable and to build the namelist
# Build the GSI namelist on-the-fly
if [ $ensmem -eq 00 ]; then
   cp ${PARMwofs}/wofs_gsiparm.anl.mean gsiparm.anl
else
   cp ${PARMwofs}/wofs_gsiparm.anl  gsiparm.anl
fi

#ecflow_client --event ready2sub      #for next batch diag jobs to run
#export pgm=wofs_gsi
#. prep_step

#startmsg
#if [ $ensmem -gt 00 ]; then
#   ln -sf ../mean/d01/obs_input.* .
#fi
#ln -sf wrf_inout_d01 wrf_inout
echo "gsi log: $DATA/${pgmout}"
cp ${EXECwofs}/wofs_gsi .

#runline="aprun -j1 -cc depth -n 48 -N 12 -d 2 ./wofs_gsi"
runline="srun --mpi=pmi2 ./wofs_gsi"
$runline < gsiparm.anl >> $DATA/${pgmout} 2>errfile

export err=$?; # err_chk

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to 
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#

if [ $ensmem -eq 00 ]; then
   mkdir d01
   mv obs_input.* d01/.
fi

loops="01"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

#  Collect diagnostic files for obs types (groups) below
   listall="conv abi_g16 abi_g18 abi_g19"
   for type in $listall; do
      count=`ls pe*.${type}_${loop}* | wc -l`
      if [[ $count -gt 0 ]]; then
          `cat pe*.${type}_${loop}* > diag_${type}_${string}.${PDY}${cyc}${subcyc}`
          if [ $ensmem -eq 00 ]; then
            cp diag_${type}_${string}.${PDY}${cyc}${subcyc} ${COMOUT}/diag_${type}_${string}.${PDY}${cyc}${subcyc}.mean
          else
            cp diag_${type}_${string}.${PDY}${cyc}${subcyc} ${COMOUT}/diag_${type}_${string}.${PDY}${cyc}${subcyc}.mem${ensmemid}
          fi
      fi
   done
done

export err=$?; # err_chk
mv fort.201 fit_p1
mv fort.202 fit_w1
mv fort.203 fit_t1
mv fort.204 fit_q1
mv fort.205 fit_pw1
mv fort.206 fit_oz1
mv fort.207 fit_rad1
mv fort.208 fit_pcp1
mv fort.209 fit_rw1
mv fort.213 fit_sst1
mv fort.238 fit_dbz1

cat fit_p1 fit_w1 fit_t1 fit_q1 fit_pw1 fit_rad1 fit_rw1 fit_dbz1 > ${COMOUT}/wofs_d01.t${cyc}z.fits.${tmmark}.mem${ensmemid}
cat fort.210 fort.211 fort.212 fort.214 fort.215 fort.217 fort.220 > ${COMOUT}/wofs_d01.t${cyc}z.fits2.${tmmark}.mem${ensmemid}
ls -l

#cp wrf_inout ${COMOUT}/wofs.t${cyc}z.wrf_inout

# Create a flag file and check to see if all 37 flag files are available
echo "Obsdiag is complete for member ${ensmemid}" > ${COMOUT}/diagdone${cyc}00.${ensmemid}

msg="JOB $job HAS COMPLETED NORMALLY."
#postmsg "$jlogfile" "$msg"

exit 0
