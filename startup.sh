#!/bin/bash

mongoUrl="${MONGOURL}"
mongo="${MONGO:-mongo}"
mongoport="${MONGOPORT:-27017}"
elasticsearch="${ELASTICSEARCH:-elasticsearch}"
elasticport="${ELASTICPORT:-9200}"
nameSpaceSet="${NS_SET}"

function _mongo() {
    mongo --quiet --host ${mongo} --port ${mongoport} <<EOF
    $@
EOF
}

is_master_result="false"
expected_result="true"

while true;
do
  if [ "${is_master_result}" == "${expected_result}" ] ; then
    is_master_result=$(_mongo "rs.isMaster().ismaster")
    echo "Waiting for Mongod node to assume primary status..."
    sleep 3
  else
    echo "Mongod node is now primary"
    break;
  fi
done

sleep 1

if [ -z ${mongoUrl} ]; then
  echo running "mongo-connector --auto-commit-interval=0 --oplog-ts=/data/oplog.ts -m ${mongo}:${mongoport} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error"
  mongo-connector --auto-commit-interval=0 --oplog-ts=/data/oplog.ts -m ${mongo}:${mongoport} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error
else
  echo running "mongo-connector --auto-commit-interval=0 --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error"
  mongo-connector --auto-commit-interval=0 --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error
fi
