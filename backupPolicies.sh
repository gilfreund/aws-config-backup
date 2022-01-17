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

echo "Backing up IAM Policies configurations"

SUBDIR=$(mksubdir Policies)

$AWSCMD iam list-policies --scope Local --only-attached --query Policies[*].[Arn,Path,PolicyName] | while read -r arn path name ; do
	if [[ ! -d ${SUBDIR}${path}${name} ]]; then
		mkdir -p ${SUBDIR}${path}${name}
	fi
	$AWSGET iam get-policy --policy-arn ${arn} > ${SUBDIR}${path}${name}/${name}.json
	$AWSGET iam list-entities-for-policy --policy-arn ${arn} > ${SUBDIR}${path}${name}/${name}-entities.json
	VERSIONS="$($AWSCMD iam list-policy-versions --policy-arn ${arn} --query Versions[*].VersionId)"
	for version in $VERSIONS  ; do
		if [[ ! -f ${SUBDIR}${path}${name}-${version}.json ]] ; then
			$AWSGET iam get-policy-version --policy-arn ${arn} --version-id ${version} > ${SUBDIR}${path}${name}/${name}-${version}.json
		fi
	done
done

commit IAM Policy Configurations
