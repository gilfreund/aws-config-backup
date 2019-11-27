#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -z $AWSCMD ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
fi

echo "Backing up IAM Policies configurations"

SUBDIR=$(mksubdir Policies)

$AWSCMD iam list-policies --scope Local --only-attached | awk '{print $2" "$7" "$10}' | while read -r arn path name ; do
if [[ ! -d ${SUBDIR}${path} ]]; then
	mkdir -p ${SUBDIR}${path}
fi
$AWSGET iam get-policy --policy-arn ${arn} > ${SUBDIR}${path}${name}.json
$AWSGET iam list-entities-for-policy --policy-arn ${arn} > ${SUBDIR}${path}${name}-entities.json
MINVERSION="$($AWSCMD iam list-policy-versions --policy-arn ${arn} | awk '{print $4}' | cut -c2- | sort | head -1)"
MAXVERSION="$($AWSCMD iam list-policy-versions --policy-arn ${arn} | awk '{print $4}' | cut -c2- | sort | tail -1)" 
for (( version=$MINVERSION; version<=$MAXVERSION; version++ )) ; do
	if [[ ! -f ${SUBDIR}${path}${name}-v${version}.json ]] ; then
		$AWSGET iam get-policy-version --policy-arn ${arn} --version-id v${version} > ${SUBDIR}${path}${name}-v${version}.json
	fi
done
done

commit IAM Policy Configurations
