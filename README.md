# azure-devops-repository-backup

## :bulb: Introduction

Microsoft doesn't provide any built-in solution to backup the Azure Devops Services.

They ask them to trust the process as described in the [Data Protection Overview](https://docs.microsoft.com/en-us/azure/devops/organizations/security/data-protection?view=azure-devops) page.

However most companies want to keep an **on-premise** backup of their code repositories for their Disaster Recovery Plan (DRP).


## Project 

This project provides a bash script to backup all azure devops repositories of an Azure Devops Organization.

A [PowerShell version](https://github.com/Pacman1988/BackupAzureDevopsRepos) of this script has been developped by [Pacman1988](https://github.com/Pacman1988)


## :fire: Bash Script

### Prerequisite 

* Shell bash (If you're running on windows, use [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) to easily run a GNU/Linux environment)
* Azure CLI : [Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* Azure CLI - Devops Extension : [Installation guide](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
* git, jq, base64 packages (available in most Linux distributions)

Interaction with the Azure DevOps API requires a [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops).

For this backup script you'll only need to generate a PAT with read access on Code

### :computer: Launch script

![version](https://img.shields.io/badge/version-1.0.1-green)

[Release notes](/docsrelease-notes.md)

     ./backup-devops.sh [-h] -p PAT -d backup-dir -o organization -r retention [-v] [-x] [-w] -- backup Azure DevOps repositories
     where:
          -h  show this help text
          -p  personal access token (PAT) for Azure DevOps [REQUIRED]
          -d  backup directory path: the directory where to store the backup archive [REQUIRED]
          -o  Azure DevOps organization URL (e.g. https://dev.azure.com/organization) [REQUIRED]
          -r  retention days for backup files: how many days to keep the backup files [REQUIRED]
          -v  verbose mode [default is false]
          -x  dry run mode (no actual backup, only simulation) [default is false]
          -w  backup project wiki [default is true]

## :whale: Use this in docker

- Stable image version  ![version](https://img.shields.io/badge/version-1.0.1-green)
- Based on script version: ![script](https://img.shields.io/badge/version-1.0.1-green)

If you don't want to install all those prerequisities or you want to isolate this process, you can run this task in a docker image.

The docker image and its documentation is available on Docker Hub ([lionelpere/azure-devops-repository-backup](https://hub.docker.com/r/lionelpere/azure-devops-repository-backup))
### :computer: Launch script

    docker run 
        -v ´YOUR_LOCAL_BACKUP_DIRECTORY`:/data
        -e DEVOPS_PAT=`YOUR_PAT`
        -e DEVOPS_ORG_URL=`YOUR_ORGANISATION_URL` 
        -e RETENTION_IN_DAYS=7 # Will delete all files older than 7 days in the backup directory
        -e DRY_RUN=true # Will create a dummy file instead of cloning the repository
        -e WIKI=true # If you want also backup the Wiki structure of the projects
        lionelpere/azure-devops-repository-backup 
