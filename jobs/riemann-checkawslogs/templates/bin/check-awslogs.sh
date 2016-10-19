#!/bin/bash

set -e -u -x

JQ_PATH=/var/vcap/packages/jq-1.5/bin/jq
RIEMANNC_PATH=/var/vcap/jobs/riemannc/bin/riemannc
AWSCLI_PATH=/var/vcap/packages/aws-cli/bin/aws

export AWS_DEFAULT_REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | $JQ_PATH -r .region)

GLOBAL_LAST_UPDATE=0

for GROUP in  `$AWSCLI_PATH logs describe-log-groups | $JQ_PATH -r .logGroups[].logGroupName`; do
	LAST_UPDATE=$($AWSCLI_PATH logs describe-log-streams --log-group-name=$GROUP --order-by LastEventTime --descending --max-items 1 | $JQ_PATH .logStreams[].lastEventTimestamp)
	if [ -z "$LAST_UPDATE" ]; then
		LAST_UPDATE=0
	fi

	NICE_GROUP=$(echo $GROUP | tr /. - | sed s/^-//)

	${RIEMANNC_PATH} --service "awslogs.$NICE_GROUP.lastEventTimestamp" --host $(hostname) --ttl ${TTL} --metric_sint64 ${LAST_UPDATE}

    if [ "$LAST_UPDATE" -gt "$GLOBAL_LAST_UPDATE" ]; then
        GLOBAL_LAST_UPDATE=$LAST_UPDATE
    fi
done

${RIEMANNC_PATH} --service "awslogs._GLOBAL.lastEventTimestamp" --host $(hostname) --ttl ${TTL} --metric_sint64 ${GLOBAL_LAST_UPDATE}
