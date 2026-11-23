---
title: "Bandit Level 26"
description: "Bandit Level 26 — discover that a user's login shell is not bash, then break out of the restricted program that replaced it."
permalink: /docs/wargames/bandit/bandit26/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit26.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 26 — discover that a user's login shell is not bash, then break out of the restricted program that replaced it."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 26
sidebar_label: "Level 26"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
Logging in to bandit26 from bandit25 should be fairly easy... The shell for user bandit26 is not **/bin/bash**, but something else. Find out what it is, how it works and how to break out of it.

> NOTE: if you're a Windows user and typically use Powershell to
> `ssh` into bandit: Powershell is known to cause issues with the
> intended solution to this level. You should use command prompt
> instead.

Commands you may need to solve this level
-----------------------------------------
ssh, cat, more, vi, ls, id, pwd

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit25`, gain an interactive shell as `bandit26`.
</div>

### What this level teaches

How login shells work, and that many ordinary programs have built-in escape hatches.

### Key ideas

- **Login shell.** The final field of each line in `/etc/passwd` names the program run at login. It need not be a shell, and it can be a program that lets you do only one thing.
- **Pagers.** `more` shows text one screenful at a time. Interactive pagers and editors such as `vi` can launch commands, edit files and change settings, which makes them valuable stepping stones.
- **Terminal size matters.** A pager only pauses when output is taller than your window, so the size of the window affects what you can do.
- **GTFOBins.** A public catalogue of normal Unix programs that can be abused to escape restrictions.

### How to approach it

1. Look at the shell recorded for `bandit26` and read what that program does.
2. Think about what happens if the output is longer than your terminal, and what you can do in that state.
3. From inside an editor, remember that it can run commands and change the shell it uses.
4. If you use Windows, run `ssh` from Command Prompt rather than PowerShell, as the Level Goal advises.

### Why it matters

Restricted shells, kiosk systems and sudo rules that permit "just one safe command" are all defeated by this kind of escape.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit25/">Level 25</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit27/">Level 27</a></nav>

</section>

<!-- study-guide:end -->
