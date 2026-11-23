---
title: "Bandit Level 8"
description: "Bandit Level 8 — find one line in a large text file with grep."
permalink: /docs/wargames/bandit/bandit8/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit8.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 8 — find one line in a large text file with grep."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 8
sidebar_label: "Level 8"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in the file **data.txt** next to the word **millionth**

Commands you may need to solve this level
-----------------------------------------
[man](https://manpages.ubuntu.com/manpages/noble/man1/man.1.html), grep, sort, uniq, strings, base64, tr, tar, gzip, bzip2, xxd

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit7`, find the password for `bandit8`.
</div>

### What this level teaches

Searching inside files rather than for them: `grep`, the tool you will use more than any other for log and data analysis.

### Key ideas

- **`grep PATTERN FILE`** prints every line that contains the pattern.
- **Line-oriented thinking.** Unix text tools treat each line as a record; the password is on the same line as the marker word.
- Options like `-i` (ignore case), `-n` (show line numbers) and `-r` (recurse) turn grep into a general search tool.

### How to approach it

1. Look at the file's size first (`ls -l`, `wc -l`). Reading a huge file by eye is the wrong approach.
2. Search for the marker word named in the Level Goal and read the line that comes back.

### Why it matters

Log analysis, code search and threat hunting all begin with grep. Learning it early makes every later level faster.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit7/">Level 7</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
