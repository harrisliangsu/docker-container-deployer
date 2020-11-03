# Docker image 自动部署脚本

## How to use
### Define the service in file service.json with a json format
name: service name
alias: abbreviation of service name
mount: the mount file for docker container
dockerRepository: the docker repository for the service to push/pull

## Command

```bash
# Service name: eat-launch-service

# Stop service with docker stop
./deploy stop eat-launch-service
./deploy stop els

# Start service with docker start
./deploy start eat-launch-service
./deploy start els

# Restart service with docker restart
./deploy restart eat-launch-service
./deploy restart els

# Deploy service with docker run
./deploy deploy eat-launch-service 10.01
./deploy deploy els 10.01
```