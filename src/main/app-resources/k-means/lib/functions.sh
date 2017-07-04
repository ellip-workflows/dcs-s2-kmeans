#!/bin/bash

# define the exit codes
SUCCESS=0
ERR_NO_URL=5
ERR_NO_PRD=8
ERR_GDAL_VRT=10
ERR_MAP_BANDS=15
ERR_OTB_BUNDLETOPERFECTSENSOR=20
ERR_DN2REF_4=25
ERR_DN2REF_3=25
ERR_DN2REF_2=25
ERR_GDAL_VRT2=30
ERR_GDAL_TRANSLATE=35
ERR_GDAL_WARP=40
ERR_GDAL_TRANSLATE=45
ERR_GDAL_ADDO=50
ERR_PUBLISH=55

# add a trap to exit gracefully
function cleanExit ()
{
  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_NO_URL}) msg="The Sentinel-2 product online resource could not be resolved";;
    ${ERR_NO_PRD}) msg="The Landsat 8 product online resource could not be retrieved";;
    ${ERR_GDAL_VRT}) msg="Failed to create the RGB VRT";;
    ${ERR_MAP_BANDS}) msg="Failed to map RGB bands";;
    ${ERR_OTB_BUNDLETOPERFECTSENSOR}) msg="Failed to apply BundleToPerfectSensor OTB operator";;
    ${ERR_DN2REF_4}) msg="Failed to convert DN to reflectance";;
    ${ERR_DN2REF_3}) msg="Failed to convert DN to reflectance";;
    ${ERR_DN2REF_2}) msg="Failed to convert DN to reflectance";;
    ${ERR_GDAL_VRT2}) msg="Failed to create VRT with panchromatic bands";;
    ${ERR_GDAL_TRANSLATE}) msg="Failed to apply gdal_translate";;
    ${ERR_GDAL_WARP}) msg="Failed to warp";;
    ${ERR_GDAL_TRANSLATE2}) msg="Failed to apply gdal_translate";;
    ${ERR_ADDO}) msg="Failed to create levels";;
    ${ERR_PUBLISH}) msg="Failed to publish the results";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}


function main() {

  input=$1
  
  cd ${TMPDIR}

  num_steps=7

  ciop-log "INFO" "(1 of ${num_steps}) Resolve Sentinel-2 online resource"
  online_resource="$( opensearch-client ${input} enclosure )"
  [[ -z ${online_resource} ]] && return ${ERR_NO_URL}

  ciop-log "INFO" "(2 of ${num_steps}) Retrieve Sentinel-2 product from ${online_resource"
  local_s2="$( ciop-copy ${online_resource} )"
  [[ -z ${local_s2} ]] && return ${ERR_NO_PRD} 

  
  
  # clean-up
  rm -fr ${local_s2}
    
 }
