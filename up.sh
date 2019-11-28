#!/bin/bash

VERSION=`cat ./package.json | awk 'BEGIN{FS="\""}/"version": "(.+)",/{print $4}'`

if [[ "$APP_VERSION" == "" ]]; then
  TAG=$VERSION
else
  TAG=$APP_VERSION
fi

if [[ "$APP_EXPOSE_PORT" == "" ]]; then
  echo "!!!ERR: No APP_EXPOSE_PORT specified!"
  exit 1
fi
export `cat ./.env | grep DOCKER`
echo `cat ./.env | grep DOCKER`
export
if [[ "$DOCKER_DEPLOY_REPO" == "" || "$DOCKER_DEPLOY_GROUP" == "" || "$DOCKER_PROJ_NAME" == "" ]]; then
  echo "!!!ERR: No DOCKER INFO specified!"
  exit 1
fi

export `cat ./.env | grep DOCKER`
if [[ $? != 0 ]]; then
  echo '!!!ERR: Export failed!'
  exit 1
fi

# ssh @SERVER echo `$DOCKER_REPO`

docker ps | grep -q -E "$DOCKER_PROJ_NAME"
if [[ "$?" == "0" ]]; then
  echo "*** INFO: $DOCKER_PROJ_NAME is running ***"
  ### run containner
  docker rm -f $DOCKER_PROJ_NAME
  if [[ "$?" != "0" ]]; then
    echo '!!!ERR: Old service shutdown failed!'
    exit 1
  fi
fi

docker run --privileged -dit -p $APP_EXPOSE_PORT:80 --name $DOCKER_PROJ_NAME $DOCKER_DEPLOY_REPO$DOCKER_DEPLOY_GROUP$DOCKER_PROJ_NAME:$TAG
if [ "$?" != "0" ]; then
  echo '!!!ERR: Start service failed!'
  exit 1
fi

echo "*** SUCCESS ***"
exit 0
