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

echo "Backing up IAM Users"

function checkForValues {
	local result=$($AWSCMD iam $1 --user-name $OBJECT_NAME | awk {'print $2'})
	if [[ -n "${result}" ]] ; then
		if [[ -n "${2}" ]] ; then 
			$AWSGET iam $1 --user-name $OBJECT_NAME > ${TARGET_FILE}-$2.json
		else
			echo "true"
		fi
	fi
}

$AWSCMD iam generate-credential-report > /dev/null

SUBDIR=$(mksubdir users)
FEATURE=iam

$AWSCMD iam list-users | awk  -F '\t' {'print $7" "$5'} | while read -r OBJECT_NAME Path ; do
	if [[ ${#Path} -gt 1 ]] ; then
		if [[ ! -d ${SUBDIR}${Path} ]] ; then
			mkdir ${SUBDIR}${Path}
		fi
		TARGET_FILE="${SUBDIR}${Path}${OBJECT_NAME}"
	else
		TARGET_FILE="${SUBDIR}/${OBJECT_NAME}"
	fi
	
	$AWSGET iam get-user --user-name $OBJECT_NAME > ${TARGET_FILE}.json
	backupIfNotNull list-attached-user-policies attached-policies
	backupIfNotNull list-groups-for-user groups
	backupIfNotNull list-user-tags tags
	backupIfNotNull list-mfa-devices mfa
	
	$AWSCMD iam list-user-policies --user-name $OBJECT_NAME | awk {'print $2'} | while read -r PolicyNames ; do
		if [[ -n "${PolicyNames}" ]] ; then
			$AWSGET iam get-user-policy --user-name $OBJECT_NAME --policy-name $PolicyNames > ${TARGET_FILE}-policies.json
		fi
	done
	
	ACCESS_KEY_LIST=$(backupIfNotNull list-access-keys)
	if [[ "$ACCESS_KEY_LIST" == true ]] ; then
		backupIfNotNull list-access-keys keys
		$AWSCMD iam list-access-keys --user-name $OBJECT_NAME | awk -F '\t' {'print $2'} | while read -r AccessKeyId ; do
			$AWSGET iam get-access-key-last-used --access-key-id $AccessKeyId > ${TARGET_FILE}-keys-$AccessKeyId.json
		done
	fi
	
	SSH_PUBLIC_KEYS=$(backupIfNotNull list-ssh-public-keys)
	if [[ "${SSH_PUBLIC_KEYS}" == "true" ]] ; then
		$AWSGET iam list-ssh-public-keys --user-name $OBJECT_NAME > ${TARGET_FILE}-ssh.json
		$AWSCMD iam list-ssh-public-keys --user-name $OBJECT_NAME | awk -F '\t' {'print $2'} | while read SSHPublicKeyId ; do
			$AWSGET iam get-ssh-public-key --user-name $OBJECT_NAME --ssh-public-key-id $SSHPublicKeyId --encoding PEM > ${TARGET_FILE}.pem
			$AWSGET iam get-ssh-public-key --user-name $OBJECT_NAME --ssh-public-key-id $SSHPublicKeyId --encoding SSH > ${TARGET_FILE}.ssh
		done
	fi


done
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
$AWSGET iam get-credential-report > $SUBDIR/credential-report_${REPORT_DATE}.csv

commit IAM users 
