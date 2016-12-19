#!/bin/bash

set -e -u -x

TODAY=$(date +%Y.%m.%d)
YESTERDAY=$(date -d "1 day ago" +%Y.%m.%d)

JQ_PATH=/var/vcap/packages/jq-1.5/bin/jq
RIEMANNC_PATH=/var/vcap/jobs/riemannc/bin/riemannc

function raw {
  echo "${1}" | ${JQ_PATH} -R .
}

function query {
  echo $(curl "${ES_URL}/logs-${1}-${2}/_search" -d "${QUERY}" | ${JQ_PATH} ".hits.total // 0")
}

QUERY=$(${JQ_PATH} -n "{
  query: {
    range: {
      $(raw "@timestamp"): {
        gte: $(raw "now-${INTERVAL}/s")
      }
    }
  }
"})

PLATFORM_LOGS=$(( $(query "platform" ${TODAY}) + $(query "platform" ${YESTERDAY}) ))
${RIEMANNC_PATH} --service "logsearch.health.platform" --host $(hostname) --ttl ${TTL} --metric_sint64 ${PLATFORM_LOGS}

APP_LOGS=$(( $(query "app-*" ${TODAY}) + $(query "app-*" ${YESTERDAY}) ))
${RIEMANNC_PATH} --service "logsearch.health.app" --host $(hostname) --ttl ${TTL} --metric_sint64 ${APP_LOGS}
