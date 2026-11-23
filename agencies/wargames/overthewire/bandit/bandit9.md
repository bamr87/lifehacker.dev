---
title: "Bandit Level 9"
description: "Bandit Level 9 — find the only unique line in a file by pairing sort with uniq through a pipe."
permalink: /docs/wargames/bandit/bandit9/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit9.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 9 — find the only unique line in a file by pairing sort with uniq through a pipe."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 9
sidebar_label: "Level 9"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in the file **data.txt** and is the only line of text that occurs only once

Commands you may need to solve this level
-----------------------------------------
grep, sort, uniq, strings, base64, tr, tar, gzip, bzip2, xxd

Helpful Reading Material
------------------------
- [Piping and Redirection][]

[Piping and Redirection]: https://ryanstutorials.net/linuxtutorial/piping.php

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit8`, find the password for `bandit9`.
</div>

### What this level teaches

Chaining small tools with pipes, and a classic gotcha: `uniq` only compares neighbouring lines.

### Key ideas

- **Pipes.** `cmd1 | cmd2` feeds the output of the first command to the second, so simple tools combine into powerful ones.
- **`sort`** orders lines so duplicates become adjacent.
- **`uniq`** collapses adjacent duplicate lines; with options it can count them or print only those that occur once.
- Reading `man uniq` carefully shows the option you need.

### How to approach it

1. Run `uniq` on the unsorted file and see why it does not help.
2. Sort first, then pipe into `uniq` with the right option.

### Why it matters

"Sort, then count unique" is the backbone of countless one-liners, from finding the most frequent IP address in a log to spotting an outlier.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit8/">Level 8</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit10/">Level 10</a></nav>

</section>

<!-- study-guide:end -->
