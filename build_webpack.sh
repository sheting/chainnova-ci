#!/bin/bash

# build static
START=$(date +"%s")
echo '*** BUILD STATIC FILES ***'
docker-compose run --rm build ./chainnova-images/src/build_staic_wp4.sh
if [ $? != 0 ]; then
  echo '!!!ERR: Build static failed!'
  exit 1
fi
BUILD_STATIC=$(date +"%s")

# build image
## version info
TAG=`cat ./package.json | awk 'BEGIN{FS="\""}/"version": "(.+)",/{print $4}'`

## set environment
export `cat ./.env | grep DOCKER`

if [ "$DOCKER_REPO_PROJ" == "" ]; then
  echo "!!!ERR: No DOCKER_REPO_PROJ specified!"
  exit 1
fi

tagged=$DOCKER_REPO_PROJ:$TAG
latest=$DOCKER_REPO_PROJ:latest

echo '*** BUILD IMAGE ***'
sh ./chainnova-images/login.sh
docker-compose build --no-cache service
if [ $? != 0 ]; then
  echo '!!!ERR: Build image failed!'
  exit 1
fi
BUILD_COMPLETE=$(date +"%s")

# push image
if [[ "$PUSH_IMAGE" == "true" ]]; then
  echo '*** PUSH IMAGE ***'
  docker tag $latest $tagged
  docker push $latest
  docker push $tagged
  # clean local image
  sleep 5s
  dopcker rmi $tagged $latest
fi
FINISH=$(date +"%s")

echo "### Time elapsed ($(($FINISH - $START)) = $(($FINISH - $BUILD_COMPLETE)) + $(($BUILD_COMPLETE - $BUILD_STATIC)) + $(($BUILD_STATIC - $START)))s"

exit 0
