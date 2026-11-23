---
title: "Bandit Level 10"
description: "Bandit Level 10 — extract readable text from a binary file with strings and filter it with grep."
permalink: /docs/wargames/bandit/bandit10/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit10.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 10 — extract readable text from a binary file with strings and filter it with grep."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 10
sidebar_label: "Level 10"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in the file **data.txt** in one of the few human-readable strings, preceded by several '=' characters.

Commands you may need to solve this level
-----------------------------------------
grep, sort, uniq, strings, base64, tr, tar, gzip, bzip2, xxd

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit9`, find the password for `bandit10`.
</div>

### What this level teaches

Finding human-readable fragments inside data that is mostly binary.

### Key ideas

- **`strings`** scans a file and prints runs of printable characters. It is a first-look tool for reverse engineers and malware analysts.
- **Binary vs text.** Most of the file is non-printable bytes; the interesting part is a handful of text fragments.
- **Combining tools.** `strings` produces many lines, and `grep` narrows them to those matching the clue (several `=` characters).

### How to approach it

1. Try `cat` on the file and note how unhelpful it is (use `reset` afterwards if your terminal is garbled).
2. Pipe `strings` into `grep` using the pattern described in the Level Goal.

### Why it matters

`strings` is often the very first command run on an unknown executable. You will use it again in Leviathan and other binary games.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit9/">Level 9</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit11/">Level 11</a></nav>

</section>

<!-- study-guide:end -->
