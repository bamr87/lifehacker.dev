---
title: "Bandit Level 22"
description: "Bandit Level 22 — read a cron job's configuration and script to see what a scheduled task does."
permalink: /docs/wargames/bandit/bandit22/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit22.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 22 — read a cron job's configuration and script to see what a scheduled task does."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 22
sidebar_label: "Level 22"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
A program is running automatically at regular intervals from **cron**, the time-based job scheduler. Look in **/etc/cron.d/** for the configuration and see what command is being executed.

Commands you may need to solve this level
-----------------------------------------
cron, crontab, crontab(5) (use "man 5 crontab" to access this)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit21`, find the password for `bandit22`.
</div>

### What this level teaches

How Linux schedules recurring work, and why reading someone else's script is a security skill.

### Key ideas

- **cron** is a daemon that runs commands at scheduled times. System-wide entries live in `/etc/cron.d/`.
- **Crontab syntax.** Five time fields (minute, hour, day of month, month, day of week) followed by the user and the command. `man 5 crontab` explains each field.
- **Whose permissions?** A cron job runs as the user named in its entry, which may not be you.
- **Follow the data.** The job's script reads something and writes it somewhere; your job is to see where.

### How to approach it

1. List `/etc/cron.d/` and read the entry for the next user.
2. Open the script it runs and trace, line by line, what it reads and where it writes.
3. Go and look at the output location.

### Why it matters

Cron is a favourite place for misconfigurations that expose data or allow privilege escalation, and attackers also use it for persistence.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit21/">Level 21</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit23/">Level 23</a></nav>

</section>

<!-- study-guide:end -->
