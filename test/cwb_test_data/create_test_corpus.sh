#!/bin/bash

CWB_HOME=/Users/stinky/Documents/tekstlab/cwb

CWB_ENCODE=${CWB_HOME}/bin/cwb-encode
CWB_MAKEALL=${CWB_HOME}/bin/cwb-makeall
CWB_ALIGN=${CWB_HOME}/bin/cwb-align
CWB_ALIGN_ENCODE=${CWB_HOME}/bin/cwb-align-encode

CURRENT_DIR=`pwd`
REG_DIR=${CURRENT_DIR}/reg

mkdir ${CURRENT_DIR}/data_arabic_u ${CURRENT_DIR}/data_arabic_v ${CURRENT_DIR}/data_english ${REG_DIR}

${CWB_ENCODE} -c utf8 -sB -f corpus/au.utf8.t.vrt -d ${CURRENT_DIR}/data_arabic_u -R ${REG_DIR}/arabic_u -S s -P pos
${CWB_ENCODE} -c utf8 -sB -f corpus/av.utf8.vrt -d ${CURRENT_DIR}/data_arabic_v -R ${REG_DIR}/arabic_v -S s
${CWB_ENCODE} -c ascii -sB -f corpus/ep.t.vrt -d ${CURRENT_DIR}/data_english -R ${REG_DIR}/english -S s -P pos

${CWB_MAKEALL} -r ${REG_DIR} arabic_u
${CWB_MAKEALL} -r ${REG_DIR} arabic_v
${CWB_MAKEALL} -r ${REG_DIR} english

echo "ALIGNED english" >> ${REG_DIR}/arabic_u
echo "ALIGNED arabic_v" >> ${REG_DIR}/arabic_u
${CWB_ALIGN} -r ${REG_DIR} arabic_u english s
${CWB_ALIGN_ENCODE} -r ${REG_DIR} -D out.align
${CWB_ALIGN} -r ${REG_DIR} arabic_u arabic_v s
${CWB_ALIGN_ENCODE} -r ${REG_DIR} -D out.align

echo "ALIGNED arabic_u" >> ${REG_DIR}/english
${CWB_ALIGN} -r ${REG_DIR} english arabic_u s
${CWB_ALIGN_ENCODE} -r ${REG_DIR} -D out.align

echo "ALIGNED arabic_u" >> ${REG_DIR}/arabic_v
${CWB_ALIGN} -r ${REG_DIR} arabic_v arabic_u s
${CWB_ALIGN_ENCODE} -r ${REG_DIR} -D out.align
