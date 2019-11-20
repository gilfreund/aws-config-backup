#!/bin/bash -x
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -f "$RCFILE" ]] ; then
	        source "$RCFILE"
fi

$AWSCMD iam list-policies --scope Local --only-attached | awk '{print $2" "$7" "$10}' | while read -r arn path name ; do
if [[ ! -d ${WORKDIR}/policies${path} ]]; then
	mkdir -p ${WORKDIR}/policies${path}
fi
$AWSGET iam get-policy --policy-arn $arn > ${WORKDIR}/policies${path}${name}.json
$AWSGET iam list-entities-for-policy --policy-arn $arn > ${WORKDIR}/policies${path}${name}-entities.json
MINVERSION="$($AWSCMD iam list-policy-versions --policy-arn ${arn} | awk '{print $4}' | cut -c2- | sort | head -1)"
MAXVERSION="$($AWSCMD iam list-policy-versions --policy-arn ${arn} | awk '{print $4}' | cut -c2- | sort | tail -1)" 
for (( version=$MINVERSION; version<=$MAXVERSION; version++ )) ; do
	$AWSGET iam get-policy-version --policy-arn $arn --version-id $version > ${WORKDIR}/policies${path}${name}-v${version}.json
done
done

commit IAM Policy Configurations
