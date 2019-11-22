#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -f "$RCFILE" ]] ; then
	source "$RCFILE"
fi

SUBDIR=$(mksubdir environments)
$AWSCMD batch describe-compute-environments | grep COMPUTEENVIRONMENTS | awk '{ print $3 }' | while read -r Environment ; do 
$AWSGET batch describe-compute-environments --compute-environments $Environment > ${SUBDIR}/${Environment}.json
done

SUBDIR=$(mksubdir definitions)
$AWSCMD batch describe-job-definitions | grep JOBDEFINITIONS | awk '{print $2" "$3" "$4}' | while read -r arn name revision ; do
$AWSGET batch describe-job-definitions --job-definitions $arn > ${SUBDIR}/${name}-${revision}.json
done

SUBDIR=$(mksubdir queues)
$AWSCMD batch describe-job-queues | grep JOBQUEUES | awk '{print $2" "$3}'| while read -r arn name ; do
$AWSGET  batch describe-job-queues --job-queues ${arn} >  ${SUBDIR}/${name}.json 
done

commit Batch Configurations
