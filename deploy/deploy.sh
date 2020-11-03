#!/bin/bash

servicePath="./service.json"
serviceObj=""
mount=""
dockerRepository=""
serviceName=""

setServiceObj() {
    serviceObj=$(jq -r '.[] | select(.name == '\""$service"\"')' $servicePath)
    if [ ! "$serviceObj" ]; then
        serviceObj=$(jq -r '.[] | select(.alias == '\""$service"\"')' $servicePath)
    fi

    if [ ! "$serviceObj" ]; then
        echo "Cant not find service for name $service"
        exit 0
    fi
}

setServiceName() {
    serviceName=$(echo "$serviceObj" | jq -r '.name')
}

setMount() {
    mount=$(echo "$serviceObj" | jq -r '.mount')
}

setDockerRepository() {
    dockerRepository=$(echo "$serviceObj" | jq -r '.dockerRepository')
}

stop() {
    docker stop "$serviceName"
}

start() {
    docker start "$serviceName"
}

restart() {
    docker restart "$serviceName"
}

deleteContainer() {
    docker container rm $(docker container ls -f name=^/$serviceName$ -a -q)
}

parseService() {
    setServiceObj
    setMount
    setDockerRepository
    setServiceName
}

runContainer() {
    image=$dockerRepository/$serviceName:$version
    # Docker pull
    docker pull $image
    # Run
    runCMD="docker run --name $serviceName"
    # Add mont parameters
    for mountFile in $(echo "$mount" | jq -r '.[]'); do
        runCMD="$runCMD -v $mountFile"
    done
    # Add other parameters
    runCMD="$runCMD --privileged --network=host -d $image"
    echo -e "Start to run container with CMD:\n$runCMD"
    $runCMD
}

# Parse arguments
if [[ "$@" == "--help" ]]; then
    echo "-a, --action    start/stop/restart/deploy"
    echo "-s, --service   service name or abbreviation"
    echo "-v, --version   the docker image version"
    echo "--help          help info"
    echo -e "\nExample: "
    echo "No ram name:    ./deploy.sh deploy vtm 10"
    echo "Param name:     ./deploy.sh --action=deploy --service=vtm --version=10"
    echo "Param name:     ./deploy.sh -a=deploy -s=vtm -v=10"
    exit 0
fi

if [[ "$@" =~ "=" ]]; then
    for ARGUMENT in "$@"; do
        KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
        VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

        case "$KEY" in
        --version) version=${VALUE} ;;
        --service) service=${VALUE} ;;
        --action) action=${VALUE} ;;
        -v) version=${VALUE} ;;
        -s) service=${VALUE} ;;
        -a) action=${VALUE} ;;
        *) ;;
        esac
    done
else
    action=$1
    service=$2
    version=$3
fi

if [ ! "$action" ]; then
    echo "No action provided"
    exit 0
fi

if [ ! "$service" ]; then
    echo "No service provided"
    exit 0
fi

main() {
    parseService

    case "$action" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    deploy)
        if [ ! "$version" ]; then
            echo "No version provided"
            exit 0
        fi

        echo "**** Start to stop service:$serviceName ****"
        stop
        echo -e "**** End to stop service:$serviceName ****\n"

        echo "**** Start to delete container:$serviceName ****"
        deleteContainer
        echo -e "**** End to delete container:$serviceName ****\n"

        echo "**** Start to run container with service:$serviceName version:$version ****"
        runContainer
        echo -e "**** End to run container with service:$serviceName version:$version ****\n"
        ;;
    *) ;;
    esac
}

main
