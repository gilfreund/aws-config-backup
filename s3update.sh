#!/bin/bash
RCFILE="$(dirname $(readlink -f $0))/backup.rc"
if [[ -f "$RCFILE" ]] ; then
	source "$RCFILE"
else
	echo "Can't find rcfile RCFILE=$RCFILE, exiting..."
	exit 1
fi
if [[ -z $SCRIPTS_BUCKET ]] ; then
	echo "Target bucket (SCRIPTS_BUCKET) not defined, exiting ..."
	exit 1
fi
if [[ -f aws-config-backup.zip ]] ; then
	zip -f aws-config-backup *.sh *.rc -x s3update.sh
else
	zip aws-config-backup *.sh *.rc -x s3update.sh
fi
$AWSCMD s3 sync $(dirname "$(realpath $0)") $SCRIPTS_BUCKET --exclude "*" --include "*.zip"
