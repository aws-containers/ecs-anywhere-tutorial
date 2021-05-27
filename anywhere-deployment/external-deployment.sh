#!/bin/bash

export LOG_OUTPUT="external-deployment.log"

logger() {
  LOG_TYPE=$1
  MSG=$2

  COLOR_OFF="\x1b[39;49;00m"
  case "${LOG_TYPE}" in
      green)
          # Green
          COLOR_ON="\x1b[32;01m";;
      blue)
          # Blue
          COLOR_ON="\x1b[36;01m";;
      default)
          # Default
          COLOR_ON="${COLOR_OFF}";;
      *)
          # Default
          COLOR_ON="${COLOR_OFF}";;
  esac

  echo -e "${COLOR_ON} ${TIME} -- ${MSG} ${COLOR_OFF}"
  echo -e "${TIME} -- ${MSG}" >> "${LOG_OUTPUT}"
}

banner()
{
  echo "+------------------------------------------+"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}

errorcheck() {
   if [ $? != 0 ]; then
          logger "red" "Unrecoverable generic error found in function: [$1]. Check the log. Exiting."
      exit 1
   fi
}

welcome() {
  banner "ECS external deployment"
  logger "green" "This script generates the new external task definition and launch the worker task on ECS Anywhere"
  logger "green" "Press <enter> to continue..."
  read -p " "
}

envvariables() {
  banner "Env Variables"
  logger "green" "Setting up environment variables..."
  export ECS_ANYWHERE_CLUSTER_NAME=ecsAnywhereCluster
  logger "yellow" "Cluster name            : $ECS_ANYWHERE_CLUSTER_NAME"
  read -p " "
}

checkclustertask() {
  banner "Check cluster name and task id "
  logger "green" "We will check if the cluster name and task id provided exist"
  logger "green" "Press <enter> to continue..."
  read -p " "
  logger "yellow" "IN_REGION_CLUSTER_NAME = $IN_REGION_CLUSTER_NAME"
  logger "yellow" "IN_REGION_TASK_ID = $IN_REGION_TASK_ID"
  aws ecs describe-tasks --tasks $IN_REGION_TASK_ID --cluster $IN_REGION_CLUSTER_NAME >> "${LOG_OUTPUT}"  
  if [ $? != 0 ]; then
          echo "Check the cluster name and the task id. Exiting."
          exit 1 
  fi
}

gettaskparameters() {
  banner "Get tasks parameters"
  logger "green" "We are sourcing the task parameters from the in-region deployment..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  export REGIONAL_WORKER=$(aws ecs describe-tasks --tasks $IN_REGION_TASK_ID --cluster $IN_REGION_CLUSTER_NAME)
  export TASK_DEFINITION_ARN=$(echo $REGIONAL_WORKER | jq '.tasks[].taskDefinitionArn' -r)
  export TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN)
  export CHANGEME_IMAGE=$(echo $TASK_DEFINITION | jq '.taskDefinition.containerDefinitions[] | select(.image | contains("worker")) | .image' -r)
  export CHANGEME_EXECUTION_ROLE_ARN=$(echo $TASK_DEFINITION | jq '.taskDefinition.executionRoleArn' -r)
  export CHANGEME_TASK_ROLE_ARN=$(echo $TASK_DEFINITION | jq '.taskDefinition.taskRoleArn' -r)
  export CHANGEME_AWSLOGS_GROUP=$(echo $TASK_DEFINITION | jq '.taskDefinition.containerDefinitions[] | select(.image | contains("worker")) | .logConfiguration.options."awslogs-group"' -r)
  export CHANGEME_REGION=$(echo $TASK_DEFINITION | jq '.taskDefinition.containerDefinitions[] | select(.image | contains("worker")) | .logConfiguration.options."awslogs-region"' -r)
  export CHANGEME_SQS_QUEUE_URL=$(echo $TASK_DEFINITION | jq '.taskDefinition.containerDefinitions[].environment[] | select(.name=="SQS_QUEUE_URL") | .value' -r)
  echo "TASK_DEFINITION_ARN = " $TASK_DEFINITION_ARN
  echo "IMAGE =               " $CHANGEME_IMAGE
  echo "EXECUTION_ROLE_ARN =  " $CHANGEME_EXECUTION_ROLE_ARN
  echo "TASK_ROLE_ARN =       " $CHANGEME_TASK_ROLE_ARN
  echo "AWSLOGS_GROUP =       " $CHANGEME_AWSLOGS_GROUP
  echo "REGION =              " $CHANGEME_REGION
  echo "SQS_QUEUE_URL =       " $CHANGEME_SQS_QUEUE_URL

}

generateexternaltaskdef() {
  banner "Generate external task definition"
  logger "green" "We are taking the values above and applying them to the task definition template..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  sed -e s#CHANGEME_IMAGE#$CHANGEME_IMAGE# \
    -e s#CHANGEME_EXECUTION_ROLE_ARN#$CHANGEME_EXECUTION_ROLE_ARN# \
    -e s#CHANGEME_TASK_ROLE_ARN#$CHANGEME_TASK_ROLE_ARN# \
    -e s#CHANGEME_AWSLOGS_GROUP#$CHANGEME_AWSLOGS_GROUP# \
    -e s#CHANGEME_REGION#$CHANGEME_REGION# \
    -e s#CHANGEME_SQS_QUEUE_URL#$CHANGEME_SQS_QUEUE_URL# \
    ecsworker-external-task-def-template.json > ecsworker-external-task-def.json
}

registerexternaltaskdef() {
  banner "Register external task definition"
  logger "green" "We are registering the external task definition..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  aws ecs register-task-definition --cli-input-json file://ecsworker-external-task-def.json >> "${LOG_OUTPUT}"  
}

createexternalservice() {
  banner "Create external ECS service"
  logger "green" "We are creating the ECS service that will launch the external task..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  aws ecs create-service --service-name ecsworker-external-service --cluster $ECS_ANYWHERE_CLUSTER_NAME --launch-type EXTERNAL --desired-count 1 --task-definition ecsworker-external
}

main() {
  welcome
  envvariables
  checkclustertask
  gettaskparameters
  generateexternaltaskdef
  registerexternaltaskdef
  createexternalservice
}

main 

