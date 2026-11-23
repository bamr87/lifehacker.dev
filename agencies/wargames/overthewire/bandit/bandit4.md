---
title: "Bandit Level 4"
description: "Bandit Level 4 — find a hidden dotfile inside the inhere directory with ls -a."
permalink: /docs/wargames/bandit/bandit4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit4.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 4 — find a hidden dotfile inside the inhere directory with ls -a."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 4
sidebar_label: "Level 4"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in a hidden file in the **inhere** directory.

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit3`, find the password for `bandit4`.
</div>

### What this level teaches

How Unix hides files, and why that is a convention rather than a security feature.

### Key ideas

- **Dotfiles.** Any file or directory whose name starts with `.` is skipped by a plain `ls`. They typically hold per-user configuration such as `.bashrc` or `.ssh/`.
- **`ls -a`** shows "all" entries, including `.` (this directory) and `..` (the parent).
- **Hidden is not secret.** Anyone can list the files; the dot only reduces clutter.

### How to approach it

1. Enter the `inhere` directory. A plain `ls` appears empty, which is the clue.
2. Use the option that includes hidden entries, then print the file that is not `.` or `..`.
3. Combine options such as `-la` to also see permissions and sizes.

### Why it matters

Malware and attackers often hide persistence in dotfiles, and incident responders list them first. You will also meet dotfiles daily when configuring tools.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit3/">Level 3</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
