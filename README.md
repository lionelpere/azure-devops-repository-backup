# azure-devops-repository-backup

## :bulb: Introduction

Microsoft don't provide any built-in solution to backup Azure Devops Services.

They ask them to thrust the process as described in the [Data Protection Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/data-protection?view=azure-devops) page.

However most companies want to keep an **on-premise** backup of their code repositories in case of Disaster Recovery Plan (DRP).


## Project 

This project provides a bash script to backup all azure devops repositories of an Azure Devops Organization.

## :fire: Bash Script

### Prerequisite 

* Shell bash (If you're running on windows, use [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) to easily run a GNU/Linux environment)
* Azure CLI : [Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* Azure CLI - Devops Extension : [Installation guide](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
* jq, base64 packages (available in most Linux distributions)

Interaction with the Azure DevOps API requires a [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops).

For this backup script you'll only need to generate a PAT with read access on Code

### :computer: Launch script

    ./backup.sh -o DEVOPS_ORG_URL -p DEVOPS_PAT -d BACKUP_DIRECTORY --dryrun true --verbose true

    Parameters:
       -o | --organization: 
            The azure devops organisation URL (eg: https://dev.azure.com/my-company)
       -d | --directory: 
            The directory where to store the backup archive.
       -p | --pat: The Personnal Access Token (PAT) that you need to generate for your Azure Devops Account
       -x|--dryrun: true/false - If you want to create a dummy file instead of cloning the repositories
       -v|--verbose true/false - Verbose mode



## :whale: Use this in docker

If you don't want to install all those prerequisities or you want to isolate this process, you can run this task in a docker image.

The docker image and its documentation is available on Docker Hub ([lionelpere/azure-devops-repository-backup](https://hub.docker.com/repository/docker/lionelpere/azure-devops-repository-backup/))
### :computer: Launch script

    docker run 
        -v ´YOUR_LOCAL_BACKUP_DIRECTORY`:/data
        -e DEVOPS_PAT=`YOUR_PAT`
        -e DEVOPS_ORG_URL=`YOUR_ORGANISATION_URL` 
        -e RETENTION_IN_DAYS=7 # Will delete all files older than 7 days in the backup directory
        -e DRY_RUN=true # Will create a dummy file instead of cloning the repository
        lionelpere/azure-devops-repository-backup 
