#!/bin/bash
RETENTION_DAYS="${RETENTION_IN_DAYS:-7}"

if [[ -z "${DRY_RUN}" ]]; then
    ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS
else
    echo "== DRY RUN EXECUTION"
    ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS --dryrun true
fi
