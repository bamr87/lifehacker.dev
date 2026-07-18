---
title: "Deploying Django on Lambda with AWS SAM: A Field Note"
description: "Deploying Django to AWS Lambda with SAM: the template, the VPC tax, the RDS connection trap — with every cloud step flagged as not re-run here."
date: 2019-08-22
categories: [Field Notes]
tags: [engineering]
author: amr
excerpt: "Django on Lambda is real, and most of it is plumbing — VPC, RDS, secrets, S3. Here is the procedure, with the parts I could not re-run on a laptop marked as such."
preview: /images/previews/deploying-django-on-lambda-with-aws-sam-a-field-no.png
---
A framing note before anything else, because this is a Field Note and the honesty is the point: **I did not re-run the cloud deploy for this post.** `sam build`, `sam deploy`, the API Gateway it stood up, the VPC it attached, the RDS instance it talked to — all of that happened in an AWS account on a project years ago, and none of it is reproducible on the dev box that's typing this. So I'm keeping the real procedure and the real lesson, and I'm flagging every step that ends in someone else's data center as **not re-run here**. The SAM template below is correct as a template. It is not a transcript.

That's the whole contract. Now the work.

## Why SAM instead of a control panel

The pitch for [AWS SAM](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html) is that you describe the whole serverless application — the Lambda function, the API Gateway in front of it, the IAM roles, the VPC wiring — in one YAML file, and `sam deploy` turns that file into real infrastructure. SAM is a thin layer on top of CloudFormation, so anything CloudFormation can declare, SAM can too; SAM only adds shorthand for the serverless parts.

The honest reason to want this: a Django app on Lambda has a lot of moving pieces, and clicking them into existence by hand in the console is how you end up with infrastructure nobody can rebuild. A template you can read is a template you can re-create after you delete the stack at 2am. That's the actual benefit. Not magic — a file you can diff.

## The shape of the project

The Django project gets one extra file (the SAM template) and one extra entry point (the Lambda handler):

```text
my-django-app/
├── manage.py
├── my_app/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── requirements.txt
├── sam-template.yaml
└── src/
    └── lambda_function.py
```

Everything except `sam-template.yaml` and `src/lambda_function.py` is ordinary Django. The two new files are the bridge to Lambda.

## The handler: Django doesn't speak Lambda natively

Lambda hands your function an `event` and a `context`. Django wants a WSGI/ASGI request. Something has to translate, and that something is [Mangum](https://mangum.io/) — an adapter that turns a Lambda event into something an ASGI app understands and back again.

```python
# src/lambda_function.py
import os
import sys

sys.path.append('/var/task')  # where Lambda unpacks your code
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'my_app.settings')

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()

def lambda_handler(event, context):
    from mangum import Mangum
    asgi_handler = Mangum(application)
    return asgi_handler(event, context)
```

A caveat I'll flag because it bit people: Mangum is an *ASGI* adapter, and Django's ASGI support arrived in 3.0. On the older Django this project shipped with, the WSGI route is the one that worked in practice. If you're starting fresh, use `get_asgi_application()` and a modern Django; the principle — Lambda event in, HTTP response out — is the same either way.

## The dependencies

```text
django
mangum
psycopg2-binary
boto3
django-storages[boto3]
```

`psycopg2-binary` is the Postgres driver, `boto3` is the AWS SDK (for pulling secrets), and `django-storages` is what lets static files live in S3 instead of on a filesystem Lambda doesn't have.

## The SAM template (the part that is a template, not a transcript)

This is the heart of it. It declares one Lambda function, the API Gateway event that triggers it, and the security group it needs to reach a database inside a VPC.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Serverless Django Application

Globals:
  Function:
    Timeout: 30
    MemorySize: 1024
    Runtime: python3.8
    Environment:
      Variables:
        DJANGO_SETTINGS_MODULE: my_app.settings
        PYTHONPATH: /var/task

Resources:
  DjangoFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_function.lambda_handler
      CodeUri: ./
      VpcConfig:
        SecurityGroupIds:
          - !Ref LambdaSecurityGroup
        SubnetIds:
          - subnet-xxxxxxxx
          - subnet-yyyyyyyy
      Policies:
        - AWSLambdaVPCAccessExecutionRole
        - AmazonRDSFullAccess     # too broad — tighten in production
        - AmazonS3FullAccess      # too broad — tighten in production
        - SecretsManagerReadWrite # too broad — tighten in production
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /{proxy+}
            Method: ANY

  LambdaSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Access to RDS
      VpcId: vpc-zzzzzzzz
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432   # PostgreSQL
          ToPort: 5432
          CidrIp: 0.0.0.0/0   # WIDE OPEN — restrict before this is real
```

Two warnings I'm leaving in loud, because the original guide shipped them as defaults and they are the kind of default that becomes a permanent fixture:

- The `AmazonRDSFullAccess` / `AmazonS3FullAccess` / `SecretsManagerReadWrite` managed policies grant far more than this function needs. They're convenient for getting a first deploy green and dangerous to leave in. The least-privilege version is further down.
- `CidrIp: 0.0.0.0/0` on the database security group means *the whole internet can attempt to reach port 5432*. That is for a five-minute test and nothing else. Restrict it to the Lambda's own security group or the VPC CIDR.

## Where the database credentials come from

Don't hard-code them. Pull them at runtime from Secrets Manager:

```python
# settings.py (excerpt)
import os, json, boto3

def get_secret():
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=os.environ['AWS_REGION'],
    )
    response = client.get_secret_value(SecretId=os.environ['SECRET_NAME'])
    return json.loads(response['SecretString'])

secrets = get_secret()

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': secrets['DB_NAME'],
        'USER': secrets['DB_USER'],
        'PASSWORD': secrets['DB_PASSWORD'],
        'HOST': secrets['DB_HOST'],
        'PORT': secrets['DB_PORT'],
    }
}
```

This runs at import time, which means every cold start pays one Secrets Manager round-trip. That's a real cost, not a free abstraction. For a low-traffic app it's fine; if it isn't fine, cache it.

## Static files have no filesystem to live on

A Lambda's disk is ephemeral and read-mostly, so Django's usual "collect static files into a directory and serve them" model doesn't apply. Point `collectstatic` at S3:

```python
# settings.py (excerpt)
INSTALLED_APPS += ['storages']

AWS_STORAGE_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
AWS_S3_REGION_NAME = os.environ['AWS_REGION']

STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

STATIC_URL = f'https://{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com/static/'
MEDIA_URL = f'https://{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com/media/'
```

## Build and deploy — NOT re-run here

Everything from this point talks to AWS. I'm reproducing the commands because they're the real ones, but **none of these were executed for this post** — there's no account, no stack, no bill attached to the box writing this. Treat the absence of output as deliberate, not as a transcript I trimmed.

```bash
# NOT re-run here — these provision real AWS infrastructure and cost money.
sam build

sam package \
    --output-template-file packaged.yaml \
    --s3-bucket your-deployment-s3-bucket

sam deploy \
    --template-file packaged.yaml \
    --stack-name your-stack-name \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        VpcId=vpc-zzzzzzzz \
        SubnetIds="subnet-xxxxxxxx,subnet-yyyyyyyy" \
        SecretName=your-secret-name \
        S3BucketName=your-static-media-bucket \
        AWSRegion=us-east-1
```

`CAPABILITY_IAM` is the flag that says "yes, I know this template creates IAM roles, do it anyway." SAM refuses without it, on purpose — creating roles is exactly the thing you want a human to acknowledge.

## The migration problem nobody warns you about

This is the part that surprises people, so it gets its own section. Your code is now inside a VPC, talking to an RDS instance that is *also* inside the VPC and not reachable from your laptop. So `python manage.py migrate` from your terminal — the command you've run a thousand times — cannot reach the database. There is no localhost here.

Two honest options, neither pretty:

**Run migrations from inside the VPC.** Open an SSH tunnel or VPN into a host that *is* in the VPC, then run `migrate` from there:

```bash
# NOT re-run here — requires a tunnel into the VPC.
python manage.py migrate
```

**Or ship a second Lambda whose only job is migrations.** Same code, different handler, longer timeout, and you invoke it by hand after each deploy:

```yaml
MigrateFunction:
  Type: AWS::Serverless::Function
  Properties:
    Handler: manage.lambda_handler
    CodeUri: ./
    Timeout: 900   # migrations are slow; the 30s default will kill them
    VpcConfig:
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - subnet-xxxxxxxx
        - subnet-yyyyyyyy
    Environment:
      Variables:
        DJANGO_SETTINGS_MODULE: my_app.settings
        COMMAND: migrate
```

```python
# manage.py — add a Lambda entry point
def lambda_handler(event, context):
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'my_app.settings')
    from django.core.management import execute_from_command_line
    execute_from_command_line(['manage.py', os.environ['COMMAND']])
```

```bash
# NOT re-run here — invokes the deployed migration function.
aws lambda invoke \
    --function-name YourStackName-MigrateFunction-XXXXXXXXXXXX \
    response.json
```

The second option is more work to set up and far less work to live with, because it doesn't require a human and a VPN every time the schema changes. I'd pick it.

## Local testing — partially honest

SAM can run an API Gateway and Lambda emulator on your machine:

```bash
# Requires Docker; talks to local emulation, but your VPC/RDS/Secrets
# Manager calls will still reach for AWS unless you mock them.
sam local start-api
```

I'll be precise about what "local" buys you: it exercises the *routing* — does the request reach your handler, does Mangum translate it — without a deploy. It does **not** give you a local VPC or a local RDS. The moment your code calls Secrets Manager or Postgres, it's reaching for the real cloud or a mock you wrote. So `sam local start-api` is genuinely useful for handler bugs and genuinely useless for "does my database wiring work." Don't confuse the two.

## The least-privilege version (use this one)

The broad managed policies above are a foot-gun. Here's the template rewritten with parameters and scoped permissions — S3 still wide for brevity, secrets scoped to the one secret this function reads:

```yaml
Parameters:
  VpcId: { Type: String }
  SubnetIds: { Type: CommaDelimitedList }
  SecurityGroupIds: { Type: CommaDelimitedList }
  SecretName: { Type: String }
  AWSRegion: { Type: String, Default: us-east-1 }
  S3BucketName: { Type: String }

Resources:
  DjangoFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_function.lambda_handler
      CodeUri: ./
      VpcConfig:
        SecurityGroupIds: !Ref SecurityGroupIds
        SubnetIds: !Ref SubnetIds
      Policies:
        - AWSLambdaVPCAccessExecutionRole
        - Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action: [secretsmanager:GetSecretValue]
              Resource: !Sub arn:aws:secretsmanager:${AWSRegion}:${AWS::AccountId}:secret:${SecretName}*
      Environment:
        Variables:
          DJANGO_SETTINGS_MODULE: my_app.settings
          SECRET_NAME: !Ref SecretName
          AWS_REGION: !Ref AWSRegion
          S3_BUCKET_NAME: !Ref S3BucketName
```

## A few things that are true and unglamorous

- **Cold starts inside a VPC used to be brutal.** A Lambda attaching an elastic network interface to reach the VPC added seconds. AWS later fixed most of that, but if you're reading an old guide and seeing scary cold-start numbers, that's the history. Provisioned concurrency is the lever if it still hurts.
- **Lambda + RDS is a connection-count trap.** Each warm Lambda holds a database connection; scale out far enough and you exhaust RDS's connection limit. RDS Proxy exists specifically to pool those connections. Budget for it before you need it.
- **Layers keep your package small.** Heavy dependencies (Django, psycopg2) can go in a Lambda layer so your function bundle stays light. Optional, but the package-size limit is real.

## Level up

The reference material for the SAM half of this — the template syntax, the resource types, the deploy mechanics — lives on the sister site's source of truth:

- AWS SAM Developer Guide: <https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html>

That guide is documentation, not a quest — read it for the *why* behind each line of the template, then come back here for the parts AWS's docs are too polite to warn you about: the wide-open security group, the migration that can't reach localhost, and the local emulator that lies about your database.

The procedure is real. The deploy was real, once. It wasn't re-run on a laptop to write this down — and saying so is cheaper than pretending otherwise.
