#!/bin/bash
set -e # exit on error

if [ $# -lt 2 ]; then
  echo "Usage: ./test.sh [WDL] [INPUT_JSON] [DOCKER_IMAGE](optional)"
  echo "Make sure to have cromwell-31.jar in your \$PATH as an executable (chmod +x)."
  exit 1
fi

WDL=$1
INPUT=$2
if [ $# -gt 2 ]; then
  DOCKER_IMAGE=$3
else
  DOCKER_IMAGE=quay.io/encode-dcc/atac-seq-pipeline:v1.1
fi
if [ -f "cromwell-34.jar" ]; then
  echo "Skip downloading cromwell."
else
  wget -N -c https://github.com/broadinstitute/cromwell/releases/download/34/cromwell-34.jar
fi
CROMWELL_JAR=cromwell-34.jar
BACKEND_CONF=../../backends/backend.conf
BACKEND=Local
PREFIX=$(basename ${WDL} .wdl)
METADATA=${PREFIX}.metadata.json # metadata
RESULT=${PREFIX}.result.json # output

# Write workflow option JSON file
TMP_WF_OPT=$PREFIX.test_atac_wf_opt.json
cat > $TMP_WF_OPT << EOM
{
    "default_runtime_attributes" : {
        "docker" : "$DOCKER_IMAGE"
    }
}
EOM

java -Dconfig.file=${BACKEND_CONF} -Dbackend.default=${BACKEND} -jar ${CROMWELL_JAR} run ${WDL} -i ${INPUT} -o ${TMP_WF_OPT} -m ${METADATA}

# parse output metadata json
cat ${METADATA} | python -c "import json,sys;obj=json.load(sys.stdin);print(obj['outputs']['${PREFIX}.compare_md5sum.json_str'])" > ${RESULT}
cat ${RESULT}
rm -f ${METADATA} ${TMP_WF_OPT}