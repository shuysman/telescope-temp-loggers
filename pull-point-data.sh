#!/bin/bash

trap 'rm -f "$TMPFILE"' EXIT

# This is an example script to subset and download Daymet gridded daily data utilizing the netCDF Subset Service RESTful API 
# available through the ORNL DAAC THREDDS Data Server
#
# Daymet data and an interactive netCDF Subset Service GUI are available from the THREDDS web interface:
# https://thredds.daac.ornl.gov/thredds/catalogs/ornldaac/Regional_and_Global_Data/DAYMET_COLLECTIONS/DAYMET_COLLECTIONS.html
#
# Usage:  This is a sample script and not intended to run without user updates.
# Update the inputs under each section of "VARIABLES" for temporal, spatial, and Daymet weather variables.
# More information on Daymet NCSS gridded subset web service is found at:  https://daymet.ornl.gov/web_services
#
# The current Daymet NCSS has a size limit of 6GB for each single subset request. 
#
# Daymet dataset information including citation is available at:
# https://daymet.ornl.gov/
#
# Michele Thornton
# ORNL DAAC
# November 5, 2018
#
#################################################################################
# VARIABLES - Temporal subset - This example is set to full Daymet calendar years
# Note:  The Daymet calendar is based on a standard calendar year. All Daymet years have 1 - 365 days, including leap years. For leap years, 
# the Daymet database includes leap day. Values for December 31 are discarded from leap years to maintain a 365-day year.

# VARIABLES - Region - na is used a example. The complete list of regions is: na (North America), hi(Hawaii), pr(Puerto Rico)
region="na"

# VARIABLES - Daymet variables - tmin and tmax are used as examples, variables should be space separated. 
# The complete list of Daymet variables is: tmin, tmax, prcp, srad, vp, swe, dayl
##var="Deficit"
##var="tmmx tmmn"
##var="rmax"
##pathways="rcp45 rcp85"
##pathways="rcp85"
##gcms="inmcm4 NorESM1-M MRI-CGCM3 MIROC5 MIROC-ESM-CHEM IPSL-CM5A-LR HadGEM2-CC365 GFDL-ESM2G CanESM2 CSIRO-Mk3-6-0 CNRM-CM5 CCSM4 BNU-ESM"
# gcms="BNU-ESM CNRM-CM5 CSIRO-Mk3-6-0 bcc-csm1-1 CanESM2 GFDL-ESM2G GFDL-ESM2M HadGEM2-CC365 HadGEM2-ES365 inmcm4 MIROC5 MIROC-ESM MIROC-ESM-CHEM MRI-CGCM3 IPSL-CM5A-LR IPSL-CM5A-MR IPSL-CM5B-LR CCSM4 NorESM1-M bcc-csm1-1-m"
##gcms="NorESM1-M"

timestep="daily"

logger_file="data/loggers.csv"
out_dir="data/"

while IFS=, read -r name lat lon
do
    wget -O ${out_dir}${name}_tmmn.csv http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_tmmn_1979_CurrentYear_CONUS.nc?var=daily_minimum_temperature&latitude=${lat}&longitude=${lon}&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-09-11T00%3A00%3A00Z&accept=csv
    wget -O ${out_dir}${name}_tmmx.csv http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_tmmx_1979_CurrentYear_CONUS.nc?var=daily_maximum_temperature&latitude=${lat}&longitude=${lon}&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-09-11T00%3A00%3A00Z&accept=csv
done <<< $(tail -4 "$logger_file")

################################################################################
### Historical

# for par in $var; do
#     echo $par
#     TMPFILE=$(mktemp) || exit 1
#     case $par in
# 	"tmmx")
# 	    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_${par}_1979_CurrentYear_CONUS.nc?var=${timestep}_maximum_temperature&north=${north}&west=${west}&east=${east}&south=${south}&disableLLSubset=on&disableProjSubset=on&horizStride=1&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-07-10T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 	    ;;
# 	"tmmn")
# 	    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_${par}_1979_CurrentYear_CONUS.nc?var=${timestep}_minimum_temperature&north=${north}&west=${west}&east=${east}&south=${south}&disableLLSubset=on&disableProjSubset=on&horizStride=1&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-07-10T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 	    ;;
# 	"rmax")
# 	    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_${par}_1979_CurrentYear_CONUS.nc?var=${timestep}_maximum_relative_humidity&north=${north}&west=${west}&east=${east}&south=${south}&disableLLSubset=on&disableProjSubset=on&horizStride=1&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-07-10T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 	    ;;
# 	"rmin")
# 	    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_met_${par}_1979_CurrentYear_CONUS.nc?var=${timestep}_minimum_relative_humidity&north=${north}&west=${west}&east=${east}&south=${south}&disableLLSubset=on&disableProjSubset=on&horizStride=1&time_start=1979-01-01T00%3A00%3A00Z&time_end=2023-07-10T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 	    ;;
#     esac
#     nccopy -d1 -s $TMPFILE ${par}_1979_CurrentYear_${timestep}_gye.nc
#     rm -f $TMPFILE
# done;

# cdo ensmean rmax_1979_CurrentYear_${timestep}_gye.nc rmin_1979_CurrentYear_${timestep}_gye.nc rh_1979_CurrentYear_${timestep}_gye.nc
# cdo ensmean tmmx_1979_CurrentYear_${timestep}_gye.nc tmmn_1979_CurrentYear_${timestep}_gye.nc tavg_1979_CurrentYear_${timestep}_gye.nc

# ### Futures
# for model in $gcms; do
#     for scenario in $pathways; do
# 	for par in $var; do
# 	    echo $par
# 	    TMPFILE=$(mktemp) || exit 1
# 	    case $par in
# 		"tmmx")
# 		    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_macav2metdata_tasmax_${model}_r1i1p1_${scenario}_2006_2099_CONUS_${timestep}.nc?var=air_temperature&north=${north}&west=${west}&east=${east}&south=${south}&disableProjSubset=on&horizStride=1&time_start=2006-01-01T00%3A00%3A00Z&time_end=2099-12-31T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 		    ;;
# 		"tmmn")
# 		     wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_macav2metdata_tasmin_${model}_r1i1p1_${scenario}_2006_2099_CONUS_${timestep}.nc?var=air_temperature&north=${north}&west=${west}&east=${east}&south=${south}&disableProjSubset=on&horizStride=1&time_start=2006-01-01T00%3A00%3A00Z&time_end=2099-12-31T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 		    ;;
# 		"rmax")
# 		    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_macav2metdata_rhsmax_${model}_r1i1p1_${scenario}_2006_2099_CONUS_${timestep}.nc?var=relative_humidity&north=${north}&west=${west}&east=${east}&south=${south}&disableProjSubset=on&horizStride=1&time_start=2006-01-01T00%3A00%3A00Z&time_end=2099-12-31T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 		    ;;
# 		"rmin")
# 		    wget -O $TMPFILE "http://thredds.northwestknowledge.net:8080/thredds/ncss/agg_macav2metdata_rhsmin_${model}_r1i1p1_${scenario}_2006_2099_CONUS_${timestep}.nc?var=relative_humidity&north=${north}&west=${west}&east=${east}&south=${south}&disableProjSubset=on&horizStride=1&time_start=2006-01-01T00%3A00%3A00Z&time_end=2099-12-31T00%3A00%3A00Z&timeStride=1&accept=netcdf"
# 		    ;;
# 	    esac
# 	    nccopy -d1 -s $TMPFILE ${par}_${model}_${scenario}_2006-2099_${timestep}_gye.nc
# 	    rm -f $TMPFILE
# 	done;
#     done;
# done;

# # for model in $gcms; do
# #     for scenario in $pathways; do
# # 	cdo -P 12 ensmean tmmx_${model}_${scenario}_2006-2099_${timestep}_gye.nc tmmn_${model}_${scenario}_2006-2099_${timestep}_gye.nc tavg_${model}_${scenario}_2006-2099_${timestep}_gye.nc
# # 	cdo -P 12 ensmean rmax_${model}_${scenario}_2006-2099_${timestep}_gye.nc rmin_${model}_${scenario}_2006-2099_${timestep}_gye.nc rg_${model}_${scenario}_2006-2099_${timestep}_gye.nc
# #     done;
# # done;

# # parallel -j 6 cdo ensmean tmmx_{1}_{2}_2006-2099_${timestep}_gye.nc tmmn_{1}_{2}_2006-2099_${timestep}_gye.nc tavg_{1}_{2}_2006-2099_${timestep}_gye.nc ::: $gcms ::: $pathways
# # parallel -j 6 cdo ensmean rmax_{1}_{2}_2006-2099_${timestep}_gye.nc rmin_{1}_{2}_2006-2099_${timestep}_gye.nc rh_{1}_{2}_2006-2099_${timestep}_gye.nc ::: $gcms ::: $pathways
