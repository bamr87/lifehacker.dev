---
title: "Bootstrap Terraform remote state without the chicken-and-egg: make the S3 bucket first, in its own config"
description: "An S3 backend can't create the bucket it stores state in. Bootstrap it from a separate local-state config, then lock it, version it, and guard it."
date: 2026-10-28
preview: /images/previews/bootstrap-terraform-remote-state-without-the-chick.svg
categories: [Hacks]
tags: [ci-cd, security]
author: cass
excerpt: "terraform init refuses to start until a bucket exists, and Terraform is what you were going to use to make the bucket. Here's the bootstrap, plus the two ways it quietly eats your state."
permalink: /hacks/terraform-remote-state-bootstrap/
---
Here's the threat nobody models: a file called `terraform.tfstate` on your laptop. It's the only record of which cloud resources your team owns. It holds every value Terraform ever saw, in plaintext. It has no backups, no lock and no access log. And it's sitting in a Downloads-adjacent folder next to `final_FINAL_v3.zip`.

`SEVERITY: your coworker's laptop. ATTACK VECTOR: the lid closing at 5:01pm.`

When a laptop has to die and the person holding it goes on vacation in the same week, an entire production environment ends up with nothing tracking it. It's a Kubernetes cluster nobody can describe. It sits in a VPC forever, like a lighthouse with no keeper, billing quietly to a credit card that belongs to someone who left in 2023. Scale that up and nation-states would need to send spies to find out what you're running. You don't know either.

Back to Earth: the fix is moving state into a shared, locked, versioned S3 bucket, a *remote backend*. The it-journey.dev [System Engineer quest report](https://it-journey.dev/quest-reports/2026-07-10-system-engineer-1000/) is where this one came up. There's a catch that every tutorial covers in one sentence and every engineer discovers in forty minutes: **the backend cannot create the bucket it lives in.** Below is the bootstrap that gets around it, then the two ways the "finished" setup still loses your state, then my three mitigations, ranked.

Everything here I ran: Terraform 1.17.1 (the `hashicorp/terraform` image) against LocalStack in Docker, so no real AWS account was harmed or billed. The output is pasted, trimmed only of blank lines and the wall of boilerplate Terraform prints on success (`[...]` marks a cut). I ran each command inside a container with LocalStack's `--endpoint-url` attached. The transcripts show the bare `terraform`/`aws` command you'd type against real AWS.

## The part where it broke before it started

First, the lab. I pulled `localstack/localstack:latest` so I wouldn't have to pay for real AWS, and it refused to start:

```console
License activation failed! 🔑❌

Reason: No credentials were found in the environment. Please set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
```

The current `latest` (2026.10.4 when I ran it) wants an account and an auth token. Pinning the older community tag `localstack/localstack:4.9` started without one. If you're following along, either pin that tag or sign up and set the token. Which convenience you sacrifice is up to you.

Now the actual bug. This is the backend block every tutorial hands you:

```hcl
# app/backend.tf
terraform {
  backend "s3" {
    bucket       = "acme-tfstate"
    key          = "app/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
```

(My lab copy also carries `endpoints`, `use_path_style`, `skip_credentials_validation`, `skip_requesting_account_id` and dummy keys so it talks to LocalStack. Delete those for real AWS.)

Run `terraform init` while the bucket doesn't exist:

```console
$ terraform init
Initializing the backend...

Error: Failed to get existing workspaces: S3 bucket "acme-tfstate" does not exist.

The referenced S3 bucket must have been previously created. If the S3 bucket
was created within the last minute, please wait for a minute or two and try
again.

Error: operation error S3: ListObjectsV2, https response error StatusCode: 404, [...] NoSuchBucket: The specified bucket does not exist
```

Then the obvious fix: add an `aws_s3_bucket "acme-tfstate"` resource to the *same* config so Terraform builds its own home. That gives you the exact same error, word for word. `init` sets up the backend before it reads a single resource, so the bucket resource never gets a chance to run. Waiting "a minute or two", as the error suggests, doesn't help either. I waited.

## The fix: a separate bootstrap config with local state

Create the bucket from a second, tiny Terraform config that has **no backend block**, so its own state stays local. Once it has run, point the real config at the bucket it made.

```text
infra/
├── bootstrap/main.tf   # makes the bucket; local state, rarely touched
└── app/backend.tf      # everything else; state lives in the bucket
```

```hcl
# bootstrap/main.tf — no backend block on purpose: this config keeps LOCAL state.
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "state" {
  bucket = "acme-tfstate"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

Bootstrap first, then the app:

```console
$ cd bootstrap && terraform init && terraform apply -auto-approve
[...]
aws_s3_bucket.state: Creating...
aws_s3_bucket.state: Creation complete after 0s [id=acme-tfstate]
aws_s3_bucket_versioning.state: Creating...
aws_s3_bucket_public_access_block.state: Creating...
aws_s3_bucket_public_access_block.state: Creation complete after 0s [id=acme-tfstate]
aws_s3_bucket_versioning.state: Creation complete after 1s [id=acme-tfstate]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

$ cd ../app && terraform init
Successfully configured the backend "s3"! Terraform will automatically
[...]
Terraform has been successfully initialized!
$ terraform apply -auto-approve
[...]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**You'll know it worked when** `app/` has a `.terraform/` directory but no `terraform.tfstate`, and the state turns up in the bucket instead:

```console
$ aws s3 ls s3://acme-tfstate --recursive
2026-10-28 22:45:30        906 app/terraform.tfstate
```

The bootstrap's own `terraform.tfstate` is still a local file. That's fine: it describes one bucket and two settings, and you'll touch it about once a year. Commit it, or keep it somewhere boring. Just don't let it be the only thing anyone knows about the bucket.

About the lock table: `use_lockfile = true` makes the S3 backend lock with a `.tflock` object in the bucket itself. That arrived in Terraform 1.10, and 1.11 deprecated the old `dynamodb_table` setting. If you're stuck on an older release, add an `aws_dynamodb_table` with a `LockID` string hash key to the bootstrap config and set `dynamodb_table` in the backend. I didn't run that older path for this post, so the only thing I'm vouching for here is the lockfile.

## Failure one: two applies, no lock, one survivor

Remote state without a lock is a shared Google Doc where everyone types blindfolded. To prove it, I gave two configs the same state key and turned the lock off. Alice's config adds `terraform_data.alice`, Bob's adds `terraform_data.bob`, and each one has a `local-exec` that sleeps 8 seconds so the applies overlap. I started Alice, then Bob two seconds later:

```console
==alice
terraform_data.alice: Creation complete after 8s [id=149f125b-6ab6-b37d-59c2-93ffbae5c614]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
==bob
terraform_data.bob: Creation complete after 8s [id=0c41ea8e-9bb6-df74-3b9d-aaf81d1f2dc4]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ terraform state list
terraform_data.alice
```

Both applies said "complete", but only one resource made it into state. Both runs read the same empty state, and each wrote back its own version. The last write won, and Bob's resource now exists without being tracked. Here's what Bob's *next* plan wants to do about it:

```console
$ terraform plan          # in Bob's directory
  # terraform_data.bob will be created
Plan: 1 to add, 0 to change, 1 to destroy.
```

It wants to create a second copy of the thing he already built, and destroy the one Alice built. Each of them did nothing wrong, and together they're one `-auto-approve` away from an outage.

With `use_lockfile = true` I ran the same race, and Bob was turned away at the door:

```console
Error: Error acquiring the state lock
Error message: operation error S3: PutObject, https response error
[...] api error PreconditionFailed: At least one of the pre-conditions you
specified did not hold
Lock Info:
  ID:        80fcfc78-b1e1-46b5-e14d-150a3c8a0760
  Path:      acme-tfstate/app/terraform.tfstate
  Operation: OperationTypeApply
  Who:       root@b6e7e3f73907
  Version:   1.17.1
```

That's a conditional `PutObject` on the lock file, refused because Alice's lock already exists. Bob waits, re-plans, and nothing gets orphaned. The error message also suggests `-lock=false` as a way around it. Read that as "here's how to bring the race condition back."

## Failure two: destroying the bootstrap

The bootstrap config is a normal Terraform config, and normal Terraform configs get `terraform destroy`ed. That might be a cleanup script, a well-meaning intern, or you at 2am thinking it's the scratch directory. With `prevent_destroy` in place:

```console
$ cd bootstrap && terraform destroy -auto-approve
Error: Instance cannot be destroyed
  on main.tf line 25:
  25: resource "aws_s3_bucket" "state" {
Resource aws_s3_bucket.state has lifecycle.prevent_destroy set, but the plan
calls for this resource to be destroyed.
```

Good. Then I removed `prevent_destroy` and ran it again. That's where it gets subtle:

```console
aws_s3_bucket_versioning.state: Destruction complete after 0s
aws_s3_bucket_public_access_block.state: Destruction complete after 0s
aws_s3_bucket.state: Destroying... [id=acme-tfstate]
Error: deleting S3 Bucket (acme-tfstate): [...] api error BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.

$ aws s3api get-bucket-versioning --bucket acme-tfstate
{
    "Status": "Suspended"
}
```

S3 refused to delete a non-empty bucket, so the "failed" destroy looks harmless. It wasn't. It had already removed the two child resources, which means versioning is now **suspended** and the public-access block is **gone**. The bucket survived, but its seatbelt and its locks didn't. Run `terraform plan` on the bootstrap after any aborted destroy.

Finally I added `force_destroy = true`, the setting people add specifically to make that BucketNotEmpty error stop:

```console
$ terraform apply -auto-approve
Apply complete! Resources: 2 added, 1 changed, 0 destroyed.
$ terraform destroy -auto-approve
Destroy complete! Resources: 3 destroyed.

$ cd ../app && terraform plan
Error: S3 bucket "acme-tfstate" does not exist.
```

Three resources destroyed, and every state file in the bucket went with them, every version included, because emptying the bucket is what `force_destroy` does. The infrastructure those files described is still running and billing. Terraform has just forgotten all of it. We're back at the lighthouse.

## The three mitigations, ranked

1. **Turn the lock on: `use_lockfile = true` in the backend block.** It's the cheapest of the three, and without it two simultaneous applies silently lose a resource while both report success (tested above). Never pass `-lock=false`. If a lock really is stale because a run died, find who holds it from the `Lock Info` block and use `terraform force-unlock <ID>` once you've confirmed that run is dead. Don't just disable locking. (I didn't need `force-unlock` in this lab, so that part is from the docs, not from a run.)
2. **Make the bucket hard to delete: `prevent_destroy = true` on the bucket, and never `force_destroy`.** I tested this above: `prevent_destroy` stopped the destroy cold, and `force_destroy` erased every state version in one command. Keep the bootstrap in its own directory, out of any wrapper script that loops `terraform destroy` over folders. After a destroy aborts halfway, run `terraform plan` there to put back the versioning and access block it already removed.
3. **Version the bucket and block public access.** State is plaintext. My test value turned up verbatim in the state object (`"value": "pretend-this-is-a-database"`), and so would your database passwords. Versioning means a bad write is recoverable: after two applies, `aws s3api list-object-versions --bucket acme-tfstate --prefix app/terraform.tfstate` listed four versions (the latest at 920 bytes, the one before at 906). The public-access block means the file stays off the open internet. I confirmed both with `aws s3api get-bucket-versioning` (`"Status": "Enabled"`) and `get-public-access-block` (all four flags `true`).

Not on the list, but true: whoever can read this bucket can read every secret Terraform touches. Grant bucket access like it's the production database password, because some of what's in there is exactly that.

## When this goes wrong

- **`init` says the bucket doesn't exist, but you just made it.** Check that the backend's `region` matches the bucket's region, and that the backend `bucket` name matches the bootstrap's name exactly. Waiting "a minute or two" won't fix a typo.
- **You already have local state and you're adding the backend now.** Run `terraform init -migrate-state` in that directory and answer `yes` to copy the existing state up. Don't delete the local file until `terraform state list` against the backend shows everything. I didn't migrate existing state in this lab; that's the documented path, not a captured one.
- **You lost the bootstrap's local state.** The bucket and the app state in it are fine. You're only missing the record of the bucket itself, which you'd re-adopt with an `import` block. I didn't run that path here, so treat it as a pointer to read about, not a tested step.
