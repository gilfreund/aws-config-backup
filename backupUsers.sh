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

function checkForValues {
	local result=$($AWSCMD iam $1 --user-name $UserName | awk {'print $2'})
	if [[ -n "${result}" ]] ; then
		if [[ -n "${2}" ]] ; then 
			$AWSGET iam $1 --user-name $UserName > ${TARGET_FILE}-$2.json
		else
			echo "true"
		fi
	fi
}

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
	checkForValues list-attached-user-policies attached-policies
	checkForValues list-groups-for-user groups
	checkForValues list-user-tags tags
	checkForValues list-mfa-devices mfa
	
	$AWSCMD iam list-user-policies --user-name $UserName | awk {'print $2'} | while read -r PolicyNames ; do
		if [[ -n "${PolicyNames}" ]] ; then
			$AWSGET iam get-user-policy --user-name $UserName --policy-name $PolicyNames > ${TARGET_FILE}-policies.json
		fi
	done
	
	ACCESS_KEY_LIST=$($AWSCMD iam list-access-keys --user-name $UserName | awk -F '\t' {'print $2'})
	if [[ -n "${ACCESS_KEY_LIST}" ]] ; then
		$AWSGET iam list-access-keys --user-name $UserName > ${TARGET_FILE}-keys.json
		echo $ACCESS_KEY_LIST | while read -r AccessKeyId ; do
			$AWSGET iam get-access-key-last-used --access-key-id $AccessKeyId > ${TARGET_FILE}-keys-$AccessKeyId.json
		done
	fi
	
	SSH_PUBLIC_KEYS=$($AWSCMD iam list-ssh-public-keys --user-name $UserName | awk -F '\t' {'print $2'})
	if [[ -n "${SSH_PUBLIC_KEYS}" ]] ; then
		$AWSGET iam list-ssh-public-keys --user-name $UserName > ${TARGET_FILE}-ssh.json
		echo $SSH_PUBLIC_KEYS | while read -r SSHPublicKeyId ; do
			$AWSGET iam get-ssh-public-key --user-name $UserName --ssh-public-key-id $SSHPublicKeyId --encoding PEM > ${TARGET_FILE}.pem
			$AWSGET iam get-ssh-public-key --user-name $UserName --ssh-public-key-id $SSHPublicKeyId --encoding SSH > ${TARGET_FILE}.ssh
		done
	fi


done
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
$AWSGET iam get-credential-report > $SUBDIR/credential-report_${REPORT_DATE}.csv

commit IAM UserNames
