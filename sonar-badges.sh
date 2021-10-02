#!/bin/bash

function line() {
  echo -e "\n----------------------------------------------------------------------------------------------------"
}

function log() {
  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') $1"
  line
}

function append_default_badge(){
   DEFAULT_BADGE_NAME="Pipeline"
   PROJECT_BADGE=$(curl -fs -X GET -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$1/badges?name=$DEFAULT_BADGE_NAME" | jq -r ".[].name")
  
  if [ "$PROJECT_BADGE" == "" ]; then
    echo "Setting up $DEFAULT_BADGE_NAME"
    curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "link_url=https://gitlab.trendyol.com/%25%7Bproject_path%7D/-/commits/%25%7Bdefault_branch%7D&image_url=https://gitlab.trendyol.com/%25%7Bproject_path%7D/badges/%25%7Bdefault_branch%7D/pipeline.svg&name=Pipeline" "$GITLAB_API_URL/projects/$1/badges"
    sleep 0.1
   else
    echo "$DEFAULT_BADGE_NAME badge already exist"
   fi
}

function append_badge(){  

  METRICS="$BADGE_METRICS"
  echo "METRICS loaded: $METRICS"
  
  PROJECT_NAME=$(curl -fs -X GET -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$2" | jq -r ".path")
  LINK_URL="$SONAR3_URL/dashboard?id=$PROJECT_NAME%2D%25%7Bdefault_branch%7D"
  
  append_default_badge $2

  for METRIC in $(echo $METRICS | tr ";" "\n")
  do

   BADGE_NAME=$METRIC
   PROJECT_BADGE=$(curl -fs -X GET -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$2/badges?name=$METRIC" | jq -r ".[].name") | xargs

   IMAGE_URL="https://sonar3.trendyol.com/api/project_badges/measure?project=$PROJECT_NAME%2D%25%7Bdefault_branch%7D%26metric=$METRIC"
   
   if echo $PROJECT_NAME | grep -q "service\|api\|service-core" && [ "$PROJECT_BADGE" == "" ]
   then
    echo "Setting up badge for Project:$2 ProjectName:$PROJECT_NAME"
    curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "link_url=$LINK_URL&image_url=$IMAGE_URL&name=$BADGE_NAME" "$GITLAB_API_URL/projects/$2/badges"
    sleep 0.1
   else
    echo "PROJECT_BADGE:$PROJECT_BADGE"
    echo "PROJECT_NAME:$PROJECT_NAME"
   fi

done
}

function setup_group() { 

  GROUP_PATH=$(curl -fs -X GET -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/groups/$1?with_projects=false" | jq ".full_path")
  log "Retrieve (#$1) $GROUP_PATH projects"

  PROJECTS=$(curl -fs -X GET -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/groups/$1/projects?simple=true&include_subgroups=true&per_page=100&with_shared=false" | jq ".[].id")
  
  log "Projects are $PROJECTS"

  for PROJECT_ID in $PROJECTS
  do
    append_badge $1 $PROJECT_ID
  done
  line
}

function start() {
  log "Sonar setup has started!"
  
  for GROUP in $GROUPS
  do
     setup_group $GROUP
  done

  log "Sonar setup has finished!"
}


GROUPS="1234"
GITLAB_API_URL="https://gitlab.domain/api/v4"
SONAR3_URL="https://mysonar.com"
GITLAB_TOKEN="mygitlabtoken"

start
