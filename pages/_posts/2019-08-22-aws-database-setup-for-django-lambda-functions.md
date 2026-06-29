---
title: "Wiring an RDS Database to Django on Lambda: A Field Note"
description: "An honest write-up of connecting Django on Lambda to an RDS Postgres database through a VPC, security groups, RDS Proxy, and Secrets Manager."
date: 2019-08-22
categories: [Field Notes]
tags: [aws, django, lambda, rds, vpc, secrets-manager]
author: amr
excerpt: "The procedure that taught me Lambda timeouts are usually a networking story wearing a database costume — and which steps I can't re-run on a laptop."
---

A note before I start, because honesty is the format here: I cannot re-run most of this on a plain dev box. This is an AWS-only procedure. Creating an RDS instance, drawing security-group rules between a Lambda function and a database, standing up an RDS Proxy, storing credentials in Secrets Manager — every one of those steps lives in someone's AWS account, costs money, and leaves no trace on a laptop. So I have not verified the console clicks or the CLI calls below by running them today. What I am preserving is the real procedure and the one lesson that cost the most to learn. Where a step can only be checked inside AWS, I say so.

The goal is small to describe and large to debug: a Django app running on Lambda that can talk to a Postgres database without leaking its password or opening the database to the internet.

## The lesson, up front

A Lambda function that times out trying to reach a database is almost never a database problem. It is a networking problem wearing a database costume.

Lambda runs outside your VPC by default. RDS, if you configured it correctly, runs *inside* one and refuses public connections. Those two facts do not introduce themselves. The function calls out, the packet has nowhere to go, and thirty seconds later you get a timeout that says nothing about the actual cause. I spent the timeouts blaming credentials. The credentials were fine. The function was not in the room with the database.

Everything below is the work of getting them into the same room — and then handing them a key they don't have to memorize.

## Step 1: Pick an engine

RDS speaks several dialects Django is happy with: PostgreSQL, MySQL, MariaDB, and Aurora (MySQL- or Postgres-compatible). This note uses **PostgreSQL**, because that's what the original build used. Nothing here is Postgres-specific except the port number and the driver.

## Step 2: Create the RDS instance

*Cannot verify on a dev box — this provisions a real, billable database.*

In the console: **RDS → Databases → Create database → Standard create**, engine **PostgreSQL**, latest version. The settings that matter later:

- **DB instance identifier**, master username, and a strong master password. Write these down somewhere that is not a code comment.
- **Public access: No.** This is the whole security posture in one toggle. The database should be reachable only from inside your VPC.
- **VPC:** the same VPC your Lambda function will live in. (Hold this thought. It is the thing I got wrong.)
- **Security group:** a new one is fine; you'll edit its rules in Step 3.
- **Port:** `5432` for Postgres.

Turn on **Deletion Protection** while you're here. The free, untouched version of me would not have, and the free, untouched version of me would have eventually deleted the wrong database.

The CLI does the same thing in one call. I am showing it as a reference, not as something I ran:

```bash
# NOT run here — this creates a real, billable RDS instance.
aws rds create-db-instance \
    --db-instance-identifier my-django-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username dbadmin \
    --master-user-password 'CHANGE_ME' \
    --vpc-security-group-ids sg-xxxxxxxx \
    --db-subnet-group-name my-subnet-group \
    --no-publicly-accessible
```

## Step 3: The networking, which is the actual job

This is the part the title undersells. Three things have to line up, and AWS will let you get all three subtly wrong without complaint.

1. **Same VPC.** The Lambda function and the RDS instance must be in the same VPC. Different VPCs cannot see each other without extra plumbing you do not want.
2. **The RDS security group's inbound rule** allows Postgres (TCP `5432`) *from the Lambda function's security group by ID* — not from an IP range. This is the rule I always botch by reaching for an IP address first, then regret.
3. **The Lambda function's security group** allows outbound traffic to the database on `5432`.

Use **private subnets** for both. The database has no business on a public subnet, and neither does the function that talks to it.

I cannot show you "it worked" output for this step, because the only proof is a connection succeeding later — and that connection only happens inside AWS. The tell, when it's wrong, is a timeout. The tell, when it's right, is silence followed by rows.

## Step 4: RDS Proxy (optional, and I'd do it)

*Cannot verify on a dev box.*

Lambda's whole personality is "spin up a hundred copies of me at once." A database's whole personality is "please do not open a hundred connections at once." RDS Proxy sits between them and pools connections so the burst doesn't knock the database over.

In the console: **RDS → Proxies → Create proxy**, engine **PostgreSQL**, target your RDS instance, same VPC and subnets as the function. Give it an IAM role that can read from Secrets Manager (Step 5). When the proxy is up, you connect Django to the **proxy endpoint**, not the database endpoint — that swap is easy to forget, and forgetting it quietly defeats the point of having a proxy.

I'm flagging this as recommended rather than tested. I did not stand up a proxy today; the reasoning above is the reasoning, not a benchmark.

## Step 5: Stop putting the password in the code

*Cannot verify on a dev box.*

Store the database credentials in **Secrets Manager** (**Store a new secret → Credentials for RDS database**), name it something you'll recognize, and point it at your instance. Then give the Lambda function's execution role permission to read exactly that secret — not all secrets, that one:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:my-django-db-secret-*"
    }
  ]
}
```

The trailing `-*` matters: Secrets Manager appends a random suffix to the ARN, and a policy without the wildcard fails to match the real secret. That is another thing AWS does not tell you until it denies you.

## Step 6: Put the function in the room

*Cannot verify on a dev box.*

Back in the Lambda console, **Configuration → VPC**: select the **same VPC, subnets, and security groups** as the RDS instance. This is the step that fixes the timeout from the top of the note. Until you do it, the function is outside, knocking.

While you're in Configuration:

- Set environment variables for the secret name and region.
- Make sure the execution role has the Secrets Manager permission from Step 5.
- Raise the **timeout** (30 seconds is a sane floor — the first cold connection is slow) and give it enough **memory** that it isn't starved for CPU.

## Step 7: Teach Django to read the secret

This is the one part I *can* show as ordinary code, because it's plain Python — though I have not executed it here, since it needs the AWS environment and a live secret to do anything. At runtime, Django pulls credentials from Secrets Manager instead of from a settings file:

```python
import os
import json
import boto3
from botocore.exceptions import ClientError


def get_secret():
    secret_name = os.environ["SECRET_NAME"]
    region_name = os.environ["AWS_REGION"]

    client = boto3.session.Session().client(
        service_name="secretsmanager", region_name=region_name
    )
    try:
        response = client.get_secret_value(SecretId=secret_name)
    except ClientError:
        raise
    return json.loads(response["SecretString"])


secrets = get_secret()

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": secrets["dbname"],
        "USER": secrets["username"],
        "PASSWORD": secrets["password"],
        "HOST": secrets["host"],   # the RDS Proxy endpoint, if you built one in Step 4
        "PORT": secrets.get("port", "5432"),
        "CONN_MAX_AGE": 600,       # reuse connections for 10 minutes
    }
}
```

Two things `boto3` will not warn you about: the deployment package has to include `boto3` (it ships in the Lambda runtime, but pin it if you bundle your own), and the driver has to be there too — `psycopg2-binary` for Postgres. And if you built the proxy, `secrets["host"]` is the proxy endpoint. If you point it at the database endpoint anyway, everything works, and you've quietly thrown away the connection pooling.

## Step 8: Migrations, which Lambda makes weird

*Cannot verify on a dev box.*

There's no shell on a Lambda function, so `python manage.py migrate` has to happen some other way. Two honest options:

- **Run migrations from inside a Lambda invocation** — a small handler that calls Django's `execute_from_command_line(["manage.py", "migrate"])`. Crude, but it runs inside the VPC, so it can actually reach the database.
- **Run them from a machine that can see the database** — your laptop through an SSH tunnel via a bastion host, or a CI runner in the VPC. Since the database has no public access (Step 2, on purpose), "just run migrate locally" only works if you've built the tunnel first.

I'm listing both rather than recommending one, because the right answer depends on whether you have a bastion host already, and I'm not going to pretend I tested either path today.

## What I'd actually keep from this

Strip away the console clicks and the procedure reduces to four sentences:

- Same VPC, or nothing talks to anything.
- Security groups reference each other by ID, not by IP.
- The password lives in Secrets Manager, and the IAM policy that reads it needs the wildcard suffix.
- A timeout is a networking story until proven otherwise.

The rest — proxy, encryption, `CONN_MAX_AGE`, enhanced monitoring — is real and worth doing, and I have flagged it as advice rather than benchmark because I did not re-run any of it on the way to writing this. The point of a Field Note is to keep the lesson and admit the gap. The gap here is the entire AWS account I don't have open in front of me.
