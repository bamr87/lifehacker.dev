---
title: "Auto-deploy a Jekyll site over FTP from CI (the Travis recipe, legacy but real)"
description: "Build Jekyll in CI and FTP _site to a host that only speaks FTP via ncftp. The real .travis.yml, the deploy script, and the rm -rf window that downs your site."
date: 2025-11-16
collection: hacks
author: amr
excerpt: "FTP-only host, GitHub repo, no money for a fancy pipeline. The CI recipe that bridges them — and the deploy script bug that quietly nukes your live site mid-upload."
tags: [jekyll, ci, ftp, travis, deployment]
---

Some hosting plans give you exactly one way in: FTP. No SSH, no rsync, no git push, no S3. One username, one password, and a folder called `wwwroot` that your website lives in. Meanwhile your source sits on GitHub and you would like, very much, to stop dragging files into FileZilla by hand every time you fix a typo.

This is the bridge: CI builds the Jekyll site on every push, then a deploy script FTPs the compiled `_site` up to the host. The original recipe here used Travis CI, and Travis CI for open-source repos is mostly a ghost town now — but the mechanism is the part worth keeping. The build-then-FTP shape ports to any runner that gives you a Linux box and a place to stash three secrets.

We are going to show the working recipe, then the part of it that will take your site offline if the upload ever fails. That second part is not in the original. We found it by reading the script too closely.

## The shape

Three pieces, all in your repo root:

- `.travis.yml` — tells CI when to build, what Ruby to use, and what to run.
- `_scripts/build.sh` — compiles the site.
- `_scripts/deploy.sh` — pushes `_site` over FTP, but only on a real push (not a PR).

The FTP credentials never go in the repo. They live in the CI provider's secret settings as `USERNAME`, `PASSWORD`, and `HOST`, and the deploy script reads them from the environment.

## The CI config

```yaml
language: ruby
rvm:
  - 2.3.1

install:
  - bundle install
  - gem install jekyll
  - gem install jekyll-sitemap

branches:
  only:
    - master

env:
  global:
    - JEKYLL_ENV=production

script:
  - chmod +x _scripts/build.sh
  - _scripts/build.sh

after_success:
  - chmod +x _scripts/deploy.sh
  - _scripts/deploy.sh

sudo: false
addons:
  apt:
    packages:
      - ncftp
```

Three lines earn their keep here:

- `branches: only: master` — CI builds the default branch and ignores the rest, so a work-in-progress branch doesn't ship a half-finished site.
- `JEKYLL_ENV=production` — Jekyll exposes this to your templates as `jekyll.environment`, so you can wrap analytics and other production-only junk in a `{% raw %}{% if jekyll.environment == "production" %}{% endraw %}` guard and keep it out of local builds.
- `addons: apt: packages: [ncftp]` — installs the FTP client the deploy step needs. `ncftp` ships `ncftpput`, which does recursive uploads non-interactively. Plain `ftp` cannot; you'd be feeding it a script line by line.

The `after_success` hook is the load-bearing detail: deploy runs *only if `script` passed*. A build that fails never reaches the FTP step, so a broken site can't overwrite a working one. That's your safety interlock, and it's free.

> Pin the Ruby version (`rvm: 2.3.1` above) to whatever your `Gemfile.lock` was resolved against. A runner that silently upgrades Ruby out from under your gems is its own afternoon. The version shown is the original's; use yours.

## The production guard, in your templates

Once `JEKYLL_ENV=production` is set in CI, gate anything you don't want firing on your laptop:

{% raw %}
```liquid
{% if jekyll.environment == "production" %}
  <!-- analytics, ad tags, verification snippets -->
{% endif %}
```
{% endraw %}

Local `jekyll serve` leaves `jekyll.environment` at its default of `development`, so the block stays out of your dev builds without a single `if`-by-hand. You'll know it worked when your analytics dashboard shows zero hits from your own machine.

## The build script

`_scripts/build.sh` is the local command you already run, with the config made explicit:

```bash
#!/bin/bash
bundle exec jekyll build --config _config.yml
```

You'll know it worked when CI's log shows the usual Jekyll summary and a `_site/` directory exists for the next step to upload.

## The deploy script — and the part where it broke

Here is the original deploy script. It works on the happy path, and it has a bug that only shows itself on the unhappy one. Read it, then read the line we flagged.

```bash
#!/bin/bash

if [[ $TRAVIS_PULL_REQUEST = "false" ]]; then
    # 1. WIPE the live directory  <-- the dangerous line
    ncftp -u "$USERNAME" -p "$PASSWORD" "$HOST" <<'EOF'
rm -rf site/wwwroot
mkdir site/wwwroot
quit
EOF

    # 2. upload the freshly built site
    cd _site || exit
    ncftpput -R -v -u "$USERNAME" -p "$PASSWORD" "$HOST" /site/wwwroot .
fi
```

The `TRAVIS_PULL_REQUEST` guard is genuinely good and the reason the script is worth keeping. On a real push that variable is the string `false`; on a pull-request build it's the PR number. The deploy only fires for the former, so a PR can be built and validated without ever touching the live host. We ran the guard logic on its own:

```bash
# lh:run
echo "# push (TRAVIS_PULL_REQUEST=false): deploy runs"
TRAVIS_PULL_REQUEST=false
if [[ $TRAVIS_PULL_REQUEST = "false" ]]; then echo "deploying"; else echo "skipped (PR)"; fi

echo
echo "# PR build (TRAVIS_PULL_REQUEST=42): deploy is skipped"
TRAVIS_PULL_REQUEST=42
if [[ $TRAVIS_PULL_REQUEST = "false" ]]; then echo "deploying"; else echo "skipped (PR)"; fi
```

Real output:

```text
# push (TRAVIS_PULL_REQUEST=false): deploy runs
deploying

# PR build (TRAVIS_PULL_REQUEST=42): deploy is skipped
skipped (PR)
```

Now the bug. Step 1 does `rm -rf site/wwwroot; mkdir site/wwwroot` **before** step 2 uploads anything. Between those two steps your live site is an empty folder. If the `ncftpput` then fails — flaky connection, wrong path, disk full, FTP server hiccup — there is nothing to fall back to. Your visitors get an empty directory until you notice and re-run.

We modeled the window locally, with directories standing in for the FTP paths:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p live && printf 'old index\n' > live/index.html
echo "# before deploy:"; ls live

rm -rf live && mkdir -p live          # what step 1 does
echo "# after the wipe, before the upload — site is empty:"
echo "files in live: $(ls live | wc -l | tr -d ' ')"
```

Real output:

```text
# before deploy:
index.html
# after the wipe, before the upload — site is empty:
files in live: 0
```

`files in live: 0` is the outage. The fix is to never delete what you can't immediately replace: upload first into a fresh directory, then swap.

```bash
#!/bin/bash

if [[ $TRAVIS_PULL_REQUEST = "false" ]]; then
    cd _site || exit

    # upload into a NEW directory; the live site is untouched if this fails
    ncftpput -R -v -u "$USERNAME" -p "$PASSWORD" "$HOST" /site/wwwroot_new .

    # only once the upload succeeded, do the swap
    ncftp -u "$USERNAME" -p "$PASSWORD" "$HOST" <<'EOF'
rename site/wwwroot site/wwwroot_old
rename site/wwwroot_new site/wwwroot
rmr site/wwwroot_old
quit
EOF
fi
```

The rename is near-instant, so the swap window is milliseconds instead of an entire upload. If `ncftpput` dies, `wwwroot` still holds the last good build and nobody sees an empty page. The script above already moves the old build aside first (`wwwroot` → `wwwroot_old`) before promoting the new one, which sidesteps the FTP servers that refuse to `rename` over an existing path.

## A second, quieter trap: the heredoc indentation

The original FTP command block was written indented inside the `if`, like this:

```bash
    ncftp ... <<EOF
    rm -rf site/wwwroot
    mkdir site/wwwroot
    quit
    EOF
```

A plain `<<EOF` heredoc takes its body **literally, leading whitespace and all** — and the closing `EOF` only ends the block when it's at column 0. Indent that closing token and bash never sees the terminator; the heredoc swallows the rest of your script. Worse, the indented body lines (`    rm -rf...`) get sent to the FTP server with their leading spaces, and a picky server rejects ` rm -rf` as an unknown command.

Two ways out. Either keep the body and the closing `EOF` flush at column 0 (what the corrected scripts above do), or switch to `<<-EOF`, which strips **leading tabs** (only tabs, not spaces) from both the body and the terminator. The flush-left version is the one that surprises no one later.

## Setting the three secrets

The deploy script reads `USERNAME`, `PASSWORD`, and `HOST` from the environment; you set them in your CI provider's repository settings, never in the repo. On Travis that was the repo's *Settings → Environment Variables*. The one rule that matters everywhere:

**Keep "display value in build log" turned off.** Build logs for public repos are public. An FTP password echoed into a log is a password on the open internet. CI providers redact known secret variables from logs, but only if you marked them secret — so mark them.

You'll know the wiring is right when a push triggers a build, the log shows `ncftpput` transferring files (with the password redacted as `[secure]` or similar), and a refresh of your live site shows the change.

## The honest accounting

This is a legacy recipe and we're not going to pretend otherwise. Travis CI walked away from reliable free open-source builds, so most people porting this will run the same three scripts on GitHub Actions or another runner instead — the `build.sh` / `deploy.sh` pair and the `ncftp` upload don't care which CI invokes them. FTP itself is plaintext unless your host offers FTPS; if it does, use it, and if it offers SFTP or rsync-over-SSH, use *that* and skip `ncftp` entirely.

But if FTP is the only door your host gives you, this is how you stop hand-uploading: build on push, gate the deploy behind a real-push check, upload to a staging directory, and swap. The part the original got right — build-passes-before-deploy, skip-on-PR, secrets-out-of-the-repo — is worth copying exactly. The part it got wrong — wipe before upload — is worth fixing before it costs you a live site at the wrong moment.
