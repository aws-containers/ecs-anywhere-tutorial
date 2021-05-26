#### Regional deployment using Copilot

This mechanism allows us to deploy the entire application architecture on ECS/Fargate in-region using [AWS Copilot CLI](https://aws.github.io/copilot-cli/). Copilot is an open source command line interface that makes it easy for developers to build, release, and operate production ready containerized applications on Amazon ECS and AWS Fargate. You should [install the Copilot binary](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Copilot.html#copilot-install) on your development environment and make sure you have Docker installed (Copilot will build the image prior to pushing it to the region). This development environment could be your workstation or a [Cloud9 IDE](https://aws.amazon.com/it/cloud9/). 

Move to the `app` directory in this repo and inspect the `./copilot/worker/manifest.yaml` file. This is the file that describes the characteristics of our deployment. Note that we also set the `AWS_REGION` variable. 

---
**NOTE**

This variable needs to be set to the region you are deploying to. 

---

Also note that AWS Copilot supports natively deploying resources for selected services (e.g. S3, EFS) but other resources need to be deployed via so called [addons](https://aws.github.io/copilot-cli/docs/developing/additional-aws-resources/). The file `./copilot/worker/addons/main-queue.yaml` contains raw CloudFormation YAML to deploy the SQS queue. 

If you are in the `app` directory you can launch this command: 
```
copilot init --app ecs-anywhere-copilot --name worker --type "Backend Service" --dockerfile "./Dockerfile" --deploy 
```
This will create the in-region architecture as described in the main [README](../../README.md) file.  

Now you can easily exec into the worker container by leveraging the `svc exec` command. In the same folder run this: 

```
copilot svc exec
Found only one deployed service worker in environment test
Execute `/bin/sh` in container worker in task 52d39a865bc84a899ae9be5a671cab7b.

Starting session with SessionId: ecs-execute-command-00eac7d90b1c930c5
# 
```
The data folder should have the following content: 
```
# ls /data
destinationfolder  sourcefolder
#
```

Congratulations, you can now move to the next steps in the tutorial.