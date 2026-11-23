---
title: "Bandit Level 24"
description: "Bandit Level 24 — write your first shell script and let a cron job run it with more privileges than you have."
permalink: /docs/wargames/bandit/bandit24/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- bandit
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit24.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 24 — write your first shell script and let a cron job run it with more privileges than you have."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 24
sidebar_label: "Level 24"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
A program is running automatically at regular intervals from **cron**, the time-based job scheduler. Look in **/etc/cron.d/** for the configuration and see what command is being executed.

**NOTE:** This level requires you to create your own first shell-script. This is a very big step and you should be proud of yourself when you beat this level!

**NOTE 2:** Keep in mind that your shell script is removed once executed, so you may want to keep a copy around...

Commands you may need to solve this level
-----------------------------------------
chmod, cron, crontab, crontab(5) (use "man 5 crontab" to access this)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit23`, find the password for `bandit24`.
</div>

### What this level teaches

Writing a script, and the danger of a privileged job that executes files other users can write.

### Key ideas

- **Shebang.** The first line `#!/bin/bash` tells the system which interpreter runs the file.
- **Executable bit.** `chmod +x` makes the script runnable; the cron user must also be able to read and run it.
- **Drop directories.** Some jobs run every file placed in a directory, then delete it. Whoever can write to that directory can run code as the job's user.
- **Permissions on your workspace.** The job runs as a different user, so the place where it writes output must allow that.

### How to approach it

1. Read the cron entry and its script and identify which directory it executes and who runs it.
2. Write a tiny script that copies the target password somewhere you can read it, test it by hand, and keep a spare copy because the job deletes the original.
3. Wait for the next scheduled run (check the schedule), then collect the result.

### Why it matters

This is a textbook privilege-escalation pattern: a root-run cron or service that executes files from a world-writable location.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit23/">Level 23</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit25/">Level 25</a></nav>

</section>

<!-- study-guide:end -->
