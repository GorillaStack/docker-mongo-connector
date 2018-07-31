#!/bin/bash

user="${MONGOUSER}"
pass="${MONGOPASS}"
mongoUrl="${MONGOURL}"
mongo="${MONGO:-mongo}"
mongoport="${MONGOPORT:-27017}"
elasticsearch="${ELASTICSEARCH:-elasticsearch}"
elasticport="${ELASTICPORT:-9200}"
nameSpaceSet="${NS_SET}"
confFile="${CONFFILE}"

function _mongo() {
    mongo --quiet --host ${mongo} --port ${mongoport} <<EOF
    $@
EOF
}

is_master_result="false"
expected_result="true"

while true;
do
  if [ "${is_master_result}" != "${expected_result}" ]; then
    is_master_result=$(_mongo "rs.isMaster().ismaster")
    echo "Waiting for Mongod node to assume primary status..."
    sleep 3
  else
    echo "Mongod node is now primary"
    break;
  fi
done

sleep 1

confFileLength=$(echo ${#confFile})
if [ $confFileLength -gt 0 ]; then
  echo "config file passed in as an env var, writing to file"
  echo $confFile > /config/mongo-connector.conf.json
fi

if [ -f /config/mongo-connector.conf.json ]; then
  echo "config file found, relying on that for namespace configuration"
  echo running "mongo-connector --auto-commit-interval=0 -v --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -c /config/mongo-connector.conf.json --continue-on-error"
  mongo-connector --auto-commit-interval=0 --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -c /config/mongo-connector.conf.json --continue-on-error
elif [ -z ${pass} ]; then
  echo running "mongo-connector --auto-commit-interval=0 -v --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error"
  mongo-connector --auto-commit-interval=0 --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error
else
  echo running "mongo-connector --auto-commit-interval=0 -v --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -a ${user} -p ${pass} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error"
  mongo-connector --auto-commit-interval=0 --enable-syslog --stdout --oplog-ts=/data/oplog.ts -m ${mongoUrl} -a ${user} -p ${pass} -t ${elasticsearch}:${elasticport} -d elastic2_doc_manager -n ${nameSpaceSet} --continue-on-error
fi
