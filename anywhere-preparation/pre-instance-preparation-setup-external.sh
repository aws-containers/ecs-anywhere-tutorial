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
  banner "ECS external preparation - phase 1"
  logger "green" "This script runs before setting up the ECS/SSM agents on the external instances"
  logger "green" "Press <enter> to continue..."
  read -p " "
}

env_variables() {
  banner "Env Variables"
  logger "green" "Setting up environment variables..."
  export ECS_ANYWHERE_CLUSTER_NAME=ecsAnywhereCluster
  export ECS_ANYWHERE_INSTANCE_ROLE_NAME=ecsAnywhereInstanceRole
  export SSM_REGISTRATION_LIMIT=10
  logger "yellow" "Cluster name            : $ECS_ANYWHERE_CLUSTER_NAME"
  logger "yellow" "Instance role           : $ECS_ANYWHERE_INSTANCE_ROLE_NAME"
  logger "yellow" "SSM registration limit  : $SSM_REGISTRATION_LIMIT"
  logger "green" "Press <enter> to continue..."
  read -p " "
}

ecscluster() {
  banner "ECS cluster"
  logger "green" "Creating the ECS cluster named $ECS_ANYWHERE_CLUSTER_NAME..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  aws ecs create-cluster --cluster-name $ECS_ANYWHERE_CLUSTER_NAME >> "${LOG_OUTPUT}"
}

createinstancerole() {
  banner "Instance role"
  logger "green" "Creating the IAM role to associate to the external instances..."
  logger "green" "Press <enter> to continue..."
  read -p " "
cat << EOF > ssm-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": [
      "ssm.amazonaws.com"
    ]},
    "Action": "sts:AssumeRole"
  }
}
EOF
  aws iam create-role --role-name $ECS_ANYWHERE_INSTANCE_ROLE_NAME --assume-role-policy-document file://ssm-trust-policy.json >> "${LOG_OUTPUT}"
  aws iam attach-role-policy --role-name $ECS_ANYWHERE_INSTANCE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore >> "${LOG_OUTPUT}"
  aws iam attach-role-policy --role-name $ECS_ANYWHERE_INSTANCE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role >> "${LOG_OUTPUT}"
  rm ssm-trust-policy.json >> "${LOG_OUTPUT}"
}

SSMkeys() {
  banner "SSM keys"
  logger "green" "Creating the SSM activation keys..."
  logger "green" "Press <enter> to continue..."
  read -p " "
  sleep 5 #this sleep is required for the IAM role created above to be available 
  aws ssm create-activation --registration-limit $SSM_REGISTRATION_LIMIT --iam-role $ECS_ANYWHERE_INSTANCE_ROLE_NAME | tee ssm-activation.json >> "${LOG_OUTPUT}" 
}

containerinstances() {
  banner "[STOP] off-line instance(s) setup"
  SSMKEY=$(cat ssm-activation.json)
  logger "green" "Congratulations, you have reached the first milestone..."
  logger "green" "There should be no new managed instances registered with SSM yet as you can see..."
  aws ssm describe-instance-information | jq ."InstanceInformationList"
  logger "green" "Now we need to setup the agent on the to-be container instances using the following exports:"
  ACTIVATION_ID=$(echo $SSMKEY | jq -r .ActivationId)
  ACTIVATION_CODE=$(echo $SSMKEY | jq -r .ActivationCode)
  echo
  echo "export ACTIVATION_ID=$ACTIVATION_ID"
  echo "export ACTIVATION_CODE=$ACTIVATION_CODE"  
  echo "export ECS_ANYWHERE_CLUSTER_NAME=$ECS_ANYWHERE_CLUSTER_NAME"
  echo "export MYREGION=$MYREGION"
  echo 
}

main() {
  welcome
  env_variables
  ecscluster
  createinstancerole
  SSMkeys
  containerinstances
}

main 

