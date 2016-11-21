#!/bin/bash
usage() {
	echo "USAGE: $0 <instance_id>"
	echo "Snapshots and stops the given instance id"
}

# make sure they gave us an instance id
if [ -z "$1" ]; then
	usage
	exit 99;
fi
INSTANCE_ID="$1"

set -eu

exec 2>&1

# where are we?
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd)/$(basename $0)"

# where is the CLI
AWS=/var/vcap/packages/aws-cli/bin/aws

# find a list of volumes for the instance
# this will also exit the program if the provided instance-id doesn't exist or is invalid
VOLUMES=$(${AWS} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output text --query 'Reservations[].Instances[].BlockDeviceMappings[].*.VolumeId')
for vol in ${VOLUMES}; do
	echo "Snapshotting ${INSTANCE_ID}/${vol}"
	${AWS} ec2 create-snapshot --volume-id ${vol} --description "Created from ${INSTANCE_ID} by $(hostname):${SCRIPTPATH}"
done

echo "Stopping ${INSTANCE_ID}"
${AWS} ec2 stop-instances --instance-ids ${INSTANCE_ID}
