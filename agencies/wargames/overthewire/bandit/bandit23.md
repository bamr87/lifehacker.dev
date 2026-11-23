---
title: "Bandit Level 23"
description: "Bandit Level 23 — read a shell script run by cron and work out what it computes and for whom."
permalink: /docs/wargames/bandit/bandit23/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit23.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 23 — read a shell script run by cron and work out what it computes and for whom."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 23
sidebar_label: "Level 23"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
A program is running automatically at regular intervals from **cron**, the time-based job scheduler. Look in **/etc/cron.d/** for the configuration and see what command is being executed.

**NOTE:** Looking at shell scripts written by other people is a very useful skill. The script for this level is intentionally made easy to read. If you are having problems understanding what it does, try executing it to see the debug information it prints.

Commands you may need to solve this level
-----------------------------------------
cron, crontab, crontab(5) (use "man 5 crontab" to access this)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit22`, find the password for `bandit23`.
</div>

### What this level teaches

Reading shell scripts critically, including who a script runs as.

### Key ideas

- **Command substitution.** `$(command)` replaces itself with that command's output, so scripts can build names or values on the fly.
- **Identity.** `whoami` prints the current user. A script run by cron reports the cron entry's user, not yours.
- **Hashing.** `md5sum` turns any text into a fixed-length fingerprint. A script can use it to derive an unguessable-looking filename from a known string.
- **Debugging.** The Level Goal suggests running the script to see its debug output; try each piece in the terminal individually.

### How to approach it

1. Read the script slowly and write in your notes what each line does.
2. Ask: what value does `whoami` return when cron runs it, and what string gets hashed?
3. Reproduce that computation yourself, then look where the script saved its result.

### Why it matters

"Security through an obscure filename" fails once the algorithm is visible. Auditing scripts and spotting such patterns is routine code-review work.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit22/">Level 22</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit24/">Level 24</a></nav>

</section>

<!-- study-guide:end -->
