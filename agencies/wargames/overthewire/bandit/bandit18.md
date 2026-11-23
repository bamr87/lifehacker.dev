---
title: "Bandit Level 18"
description: "Bandit Level 18 — compare two files with diff to find the single line that changed."
permalink: /docs/wargames/bandit/bandit18/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit18.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 18 — compare two files with diff to find the single line that changed."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 18
sidebar_label: "Level 18"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There are 2 files in the homedirectory: **passwords.old and passwords.new**. The password for the next level is in **passwords.new** and is the only line that has been changed between **passwords.old and passwords.new**

**NOTE: if you have solved this level and see 'Byebye!' when trying to log into bandit18, this is related to the next level, bandit19**

Commands you may need to solve this level
-----------------------------------------
cat, grep, ls, diff

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit17`, find the password for `bandit18`.
</div>

### What this level teaches

How to find differences between two versions of a file, and how to read a diff.

### Key ideas

- **`diff old new`** prints only the lines that differ. A `<` marks a line from the first file and `>` a line from the second.
- **Why it matters for text.** Version control, patches and configuration audits all rely on exactly this idea.
- A hint in the Level Goal: only one line changed, so the output should be tiny.

### How to approach it

1. Read `man diff`, paying attention to the default output format.
2. Decide which of the two lines is the password, using the file names in the Level Goal.
3. After you finish, log out and back in as the new user. If a message appears, it relates to the next level, so keep reading.

### Why it matters

`git diff`, code review and configuration-drift tools are all diff under another name.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit17/">Level 17</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit19/">Level 19</a></nav>

</section>

<!-- study-guide:end -->
