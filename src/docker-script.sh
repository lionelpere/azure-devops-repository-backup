#!/bin/bash
RETENTION_DAYS="${RETENTION_IN_DAYS:-7}"

if [[ "${DRY_RUN}" = "true" ]]; then
    echo "== DRY RUN EXECUTION"
    if [[ -z "${WIKI}" ]]; then
        ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS --dryrun true
    else
        echo "== INCLUDE WIKI"
        ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS --dryrun true -w
    fi
else
    if [[ -z "${WIKI}" ]]; then
        ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS
    else
        echo "== INCLUDE WIKI"
        ./backup-devops.sh -p $DEVOPS_PAT -o $DEVOPS_ORG_URL -d /data -r $RETENTION_DAYS -w
    fi
fi
