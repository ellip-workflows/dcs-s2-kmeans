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

trap cleanExit EXIT

function set_env() {

  bands="$( ciop-getparam bands )"

  export SNAP_HOME=/opt/snap
  export PATH=${SNAP_HOME}/bin:${PATH}
  export SNAP_VERSION=$( cat ${SNAP_HOME}/VERSION.txt )

  return 0
  
}

function main() {

  set_env || exit $?

  input=$1
  
  cd ${TMPDIR}

  num_steps=7

  ciop-log "INFO" "(1 of ${num_steps}) Resolve Sentinel-2 online resource"
  online_resource="$( opensearch-client ${input} enclosure )"
  [[ -z ${online_resource} ]] && return ${ERR_NO_URL}

  ciop-log "INFO" "(2 of ${num_steps}) Retrieve Sentinel-2 product from ${online_resource}"
  local_s2="$( ciop-copy -o ${TMPDIR} ${online_resource} )"
  [[ -z ${local_s2} ]] && return ${ERR_NO_PRD} 

  SNAP_REQUEST=${TMPDIR}/snap_request.xml
  
  # clean-up
  rm -fr ${local_s2}
  rm -fr ${SNAP_REQUEST}
    
  cat << EOF > ${SNAP_REQUEST}
 <?xml version="1.0" encoding="UTF-8"?>
 <graph id="Graph">
  <version>1.0</version>
  <node id="Read">
    <operator>Read</operator>
    <sources/>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <file>${local_s2}</file>
      <formatName>SENTINEL-2-MSI-MultiRes-UTM31N</formatName>
    </parameters>
  </node>
  <node id="BandSelect">
    <operator>BandSelect</operator>
    <sources>
      <sourceProduct refid="Read"/>
    </sources>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <selectedPolarisations/>
      <sourceBands>B2,B3,B4,B5,B6,B7,B8,B8A,B10,B12</sourceBands>
      <bandNamePattern/>
    </parameters>
  </node>
  <node id="Resample">
    <operator>Resample</operator>
    <sources>
      <sourceProduct refid="BandSelect"/>
    </sources>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <referenceBand/>
      <targetWidth>10980</targetWidth>
      <targetHeight>10980</targetHeight>
      <targetResolution/>
      <upsampling>Nearest</upsampling>
      <downsampling>First</downsampling>
      <flagDownsampling>First</flagDownsampling>
      <resampleOnPyramidLevels>true</resampleOnPyramidLevels>
    </parameters>
  </node>
  <node id="KMeansClusterAnalysis">
    <operator>KMeansClusterAnalysis</operator>
    <sources>
      <sourceProduct refid="Resample"/>
    </sources>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <clusterCount>14</clusterCount>
      <iterationCount>30</iterationCount>
      <randomSeed>31415</randomSeed>
      <sourceBandNames>B2,B3,B4,B5,B6,B7,B8,B8A,B10,B12</sourceBandNames>
      <roiMaskName/>
    </parameters>
  </node>
  <node id="Write">
    <operator>Write</operator>
    <sources>
      <sourceProduct.1 refid="KMeansClusterAnalysis"/>
    </sources>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <file>/Users/emathot/S2A_MSIL1C_20170526T105031_N0205_R051_T31UDQ_20170526T105518.dim</file>
      <formatName>BEAM-DIMAP</formatName>
    </parameters>
  </node>   
EOF

  gpt ${SNAP_REQUEST} || return ${ERR_SNAP}
    
 }
