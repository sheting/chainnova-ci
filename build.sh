#!/bin/bash

# build static
START=$(date +"%s")
echo '*** BUILD STATIC FILES ***'
docker-compose run --rm build ./chainnova-images/src/build_vue.sh
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

if [ "$DOCKER_PROJ_NAME" == "" ]; then
  echo "!!!ERR: No DOCKER_PROJ_NAME specified!" && exit 1
fi

if [ "$DOCKER_DEPLOY_REPO" == "" ]; then
  echo "!!!ERR: No DOCKER_DEPLOY_REPO specified!" && exit 1
fi

if [ "$DOCKER_DEPLOY_GROUP" == "" ]; then
  echo "!!!ERR: No DOCKER_DEPLOY_GROUP specified!" && exit 1
fi

DOCKER_REPO_PROJ=$DOCKER_BASE_REPO$DOCKER_DEPLOY_GROUP$DOCKER_PROJ_NAME
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
if [ "$PUSH_IMAGE" == "true" ]; then
  if [ "$DOCKER_REPO_TYPE" == "ecr" ]; then
    ECR_REPO_NAME=$DOCKER_DEPLOY_GROUP$DOCKER_PROJ_NAME
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region cn-north-1
    if [[ $? != 0 ]]; then
      echo "!!!ERR: The repository with name $ECR_REPO_NAME already exists in the $DOCKER_REPO_TYPE!"
    else
      echo "...Add lifecycle policy to the new registry."
      aws ecr put-lifecycle-policy --repository-name $ECR_REPO_NAME --lifecycle-policy-text --region cn-north-1 "file://ci/aws/ecr-policy-deleteuntagged.json"
      if [ $? != 0 ]; then
          echo "!!!Error: Add lifecycle policy failed."
      fi
    fi

  fi

  echo '*** PUSH IMAGE ***'
  docker tag $latest $tagged
  docker push $latest
  docker push $tagged
  # clean local image
  sleep 5s
  docker rmi $tagged $latest
fi
FINISH=$(date +"%s")

echo "### Time elapsed ($(($FINISH - $START)) = $(($FINISH - $BUILD_COMPLETE)) + $(($BUILD_COMPLETE - $BUILD_STATIC)) + $(($BUILD_STATIC - $START)))s"

exit 0
