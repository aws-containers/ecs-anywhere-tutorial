#### Regional deployment using Docker Compose 

This mechanism allows us to deploy the entire application architecture on ECS/Fargate in-region using the very simple Docker Compose syntax. For this, you need to download the latest version of [Docker Desktop](https://docs.docker.com/desktop/). If you want to read more about this integration check out [this blog post](https://aws.amazon.com/blogs/containers/deploy-applications-on-amazon-ecs-using-docker-compose/). Configure an `ECS context` following the procedure described [here](https://docs.docker.com/cloud/ecs-integration/#create-aws-context). 

Remember to set your account number and the region you are working with in these two variables: 
```
export ACCOUNTNUMBER=<your account>
export MYREGION=<your region>
```

Since ECR does not support "create on push" (as of this writing), we will need to create the ECR repo (called `ecsworker`) upfront and authorize the shell to push to it:  
```
ECR_ECSWORKER_REPO=$(aws ecr create-repository --repository-name ecsworker --region $MYREGION)
ECR_ECSWORKER_REPO_URI=$(echo $ECR_ECSWORKER_REPO | jq --raw-output .repository.repositoryUri)
aws ecr get-login-password --region $MYREGION | docker login --password-stdin --username AWS $ECR_ECSWORKER_REPO_URI 
```

Now clone this repo and move into the `regional-deployment` folder. If you have `sed` installed and you are on a Mac you can run the following command to replace the `ACCOUNTNUMBER` and `MYREGION` placeholders in the `docker-compose.yml` file: 
```
sed -e "s/MYREGION/$MYREGION/g" -e "s/ACCOUNTNUMBER/$ACCOUNTNUMBER/g" docker-compose-template.yml > docker-compose.yml 
```
If you have problems with `sed` (its syntax it's often very OS sensitive) you can just make sure you find replace the placeholders in the file with the content of your variables.  

If you have already configured the docker compose context as described [here](https://docs.docker.com/cloud/ecs-integration/#create-aws-context), we are ready to move to the next stage. 

Make sure you are using the docker `default` context. The `build` and the `push` are not yet supported when not in the `default` context: 
```
docker context use default
```
Build the image locally: 
```
docker compose build
```
Push the image to ECR: 
```
docker compose push
```
Switch to the docker compose `myecscontext` context: 
```
docker context use myecscontext
```
And finally, bring up the stack in AWS:
```
docker compose up
```

As you watch this coming up, pause for a second to inspect the compose file and think about what those relatively few lines of YAML are doing. The `compose up` (in the `myecscontext`) will:
* create the EFS volume
* create the ECS cluster 
* create the Fargate task definition (with the EFS mount)
* assign the SQS policy to the task definition
* create the ECS service with 1 task 
* inject all env variables required for the python worker to find things 

Fun fact: all this integration does is generating a corresponding (and much longer) CloudFormation template that generates a CloudFormation stack that you can watch deploying in your account. The `Resources` tab of your stack will show you all resources that it created. Make sure that the CloudFormation stack is deploying in the region of your choice. If not, please check your AWS CLI and Docker context configuration. 

Note that, because `docker exec` is [not yet supported](https://github.com/docker/compose-cli/issues/670), one quick way to access the EFS file system is to launch an EC2 instance making sure that you connect it to the EFS file system that docker compose has just created. The EC2 console has a very smart workflow to mount an existing file system to an EC2 instance and it takes care of setting up the Security Groups accordingly. Launch an EC2 instance and SSH into it. The workflow mounts the file system at `/mnt/efs/fs1` from where you should see the two folders that the application has created:

```
[ec2-user@ip-172-31-21-87 ~]$ ls /mnt/efs/fs1/
destinationfolder  sourcefolder
[ec2-user@ip-172-31-21-87 ~]$
```

Congratulations, you can now move to the next steps in the tutorial.

