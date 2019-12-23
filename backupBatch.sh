#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"

if [[ -z $AWSCMD || -z $TARGET_TYPE || -z $TARGET_LOCATION || -z $TEMPDIR  ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
	fi
fi

echo "Backing up Batch configurations"

SUBDIR=$(mksubdir environments)
$AWSCMD batch describe-compute-environments --query computeEnvironments[*].computeEnvironmentName | while read -r Environment ; do 
$AWSGET batch describe-compute-environments --compute-environments $Environment > ${SUBDIR}/${Environment}.json
done

SUBDIR=$(mksubdir definitions)
$AWSCMD batch describe-job-definitions --query jobDefinitions[*].[jobDefinitionArn,jobDefinitionName,revision] | while read -r arn name revision ; do
$AWSGET batch describe-job-definitions --job-definitions $arn > ${SUBDIR}/${name}-${revision}.json
done

SUBDIR=$(mksubdir queues)
$AWSCMD batch describe-job-queues --query jobQueues[*].[jobQueueArn,jobQueueName] |  while read -r arn name ; do
$AWSGET  batch describe-job-queues --job-queues ${arn} >  ${SUBDIR}/${name}.json 
done

commit Batch Configurations
