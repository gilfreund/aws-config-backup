#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -z $AWSCMD ]] ; then
	if [[ -f "$RCFILE" ]] ; then
		source "$RCFILE"
	else
		echo "Configuration file $RCFILE not found, exiting..."
		exit 1
	fi
fi

echo "Backing up EC2 configurations"

TEMPLATES=$($AWSCMD ec2 describe-launch-templates | grep LAUNCHTEMPLATES | awk '{ print $5,$7 }')
SUBDIR=$(mksubdir templates)

$AWSCMD ec2 describe-launch-templates | grep LAUNCHTEMPLATES | awk '{ print $5,$7 }' | while read -r LatestVersionNumber LaunchTemplateName ; do
$AWSGET ec2 describe-launch-templates --launch-template-names $LaunchTemplateName > ${SUBDIR}/${LaunchTemplateName}.json
	# Ignore *Batch-Lt* templates, as they are created and removed by the batch system
	if [[ $LaunchTemplateName != *Batch-Lt* ]] ; then
		StartVersionNumber=1
		for (( VersionNumber=$StartVersionNumber; VersionNumber<=$LatestVersionNumber; VersionNumber++ )) ; do
			if [[ ! -f ${SUBDIR}/templates/${LaunchTemplateName}-${VersionNumber}.json ]] ; then
				$AWSGET ec2 describe-launch-template-versions --launch-template-name $LaunchTemplateName --versions $VersionNumber > ${SUBDIR}/${LaunchTemplateName}-${VersionNumber}.json
			fi
		done
	fi
done 

commit EC2 Configurations
