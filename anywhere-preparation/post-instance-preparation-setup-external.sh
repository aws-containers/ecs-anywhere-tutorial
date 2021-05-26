#!/bin/bash

export LOG_OUTPUT="main-setup-external.log"

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
  banner "ECS external preparation - phase 2"
  logger "green" "This script runs after setting up the ECS/SSM agents on the external instances"
  logger "green" "Press <enter> to continue..."
  read -p " "
}

env_variables() {
  banner "Env Variables"
  logger "green" "Setting up environment variables..."
  export ECS_ANYWHERE_CLUSTER_NAME=ecsAnywhereCluster
  logger "yellow" "Cluster name            : $ECS_ANYWHERE_CLUSTER_NAME"
  logger "green" "Press <enter> to continue..."
  read -p " "
}

ssminstances() {
  banner "SSM managed instances"
  logger "green" "There should be new managed instances registered with SSM now..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  aws ssm describe-instance-information | jq ."InstanceInformationList"
}

checkcluster() {
  banner "ECS cluster check"
  logger "green" "Checking the cluster status (by querying it via the list-container-instances command)..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  aws ecs list-container-instances --cluster $ECS_ANYWHERE_CLUSTER_NAME | jq .

}

main() {
  welcome
  env_variables
  ssminstances
  checkcluster
}

main 

