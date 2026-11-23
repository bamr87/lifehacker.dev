---
title: "Bandit Level 19"
description: "Bandit Level 19 — read a file even though .bashrc logs you out, by running a command remotely instead of opening a shell."
permalink: /docs/wargames/bandit/bandit19/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit19.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 19 — read a file even though .bashrc logs you out, by running a command remotely instead of opening a shell."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 19
sidebar_label: "Level 19"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in a file **readme** in the homedirectory. Unfortunately, someone has modified **.bashrc** to log you out when you log in with SSH.

Commands you may need to solve this level
-----------------------------------------
ssh, ls, cat

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit18`, find the password for `bandit19`.
</div>

### What this level teaches

That an SSH login is not the only way to run something on a server, and what shell startup files do.

### Key ideas

- **`.bashrc`.** A script that bash reads when it starts, used to customise your shell. Whoever controls it controls what happens at login, and attackers abuse that for persistence.
- **Interactive vs command mode.** `ssh user@host` opens an interactive shell, but `ssh user@host COMMAND` runs one command and returns.
- Read the argument description in `man ssh` to see how the command is passed.

### How to approach it

1. Try logging in normally and observe what the modified `.bashrc` does.
2. Use the remote-command form of ssh to run `ls` first, then `cat` the file the Level Goal mentions.

### Why it matters

Automation tools such as Ansible, deployment scripts and Git over SSH all run commands remotely this way.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit18/">Level 18</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit20/">Level 20</a></nav>

</section>

<!-- study-guide:end -->
