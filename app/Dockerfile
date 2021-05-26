FROM public.ecr.aws/bitnami/python:3.8.8-prod
ADD worker.py .
RUN pip install boto3 
CMD [ "python", "-u", "./worker.py" ]