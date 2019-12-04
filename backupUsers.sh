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

echo "Backing up IAM UserNames"

$AWSCMD iam generate-credential-report > /dev/null

SUBDIR=$(mksubdir users)

$AWSCMD iam list-users | awk  -F '\t' {'print $7" "$5'} | while read -r UserName Path ; do
	if [[ ${#Path} -gt 1 ]] ; then
		if [[ ! -d ${SUBDIR}${Path} ]] ; then
			mkdir ${SUBDIR}${Path}
		fi
		TARGET_FILE="${SUBDIR}${Path}${UserName}"
	else
		TARGET_FILE="${SUBDIR}/${UserName}"
	fi
	$AWSGET iam get-user --user-name $UserName > ${TARGET_FILE}.json
	$AWSGET iam list-attached-user-policies --user-name $UserName > ${TARGET_FILE}-attached-policies.json
	$AWSGET iam list-groups-for-user --user-name $UserName > ${TARGET_FILE}-groups.json
	$AWSGET iam list-user-tags --user-name $UserName > ${TARGET_FILE}-tags.json
	$AWSCMD iam list-user-policies --user-name $UserName | awk {'print $2'} | while read -r PolicyNames ; do
		if [[ -n $PolicyNames ]] ; then
			$AWSGET iam get-user-policy --user-name $UserName --policy-name $PolicyNames > ${TARGET_FILE}-policies.json
		fi
	done
done
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
$AWSGET iam get-credential-report > $SUBDIR/credential-report_${REPORT_DATE}.csv

commit IAM UserNames
