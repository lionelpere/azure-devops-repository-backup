 # syntax=docker/dockerfile:1
FROM ubuntu:20.04
RUN apt-get update && apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg jq cron git
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
RUN AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && apt-get install azure-cli
RUN mkdir -p /data
RUN az extension add --name 'azure-devops'
COPY . /home/devops
WORKDIR /home/devops
RUN chmod 777 ./*
VOLUME ["/data"]
ENTRYPOINT ["/bin/bash", "./docker-script.sh"]

