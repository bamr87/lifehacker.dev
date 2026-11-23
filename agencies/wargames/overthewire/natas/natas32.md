---
title: "Natas Level 32"
description: "Natas Level 32 — the same Perl file-reading trick is back, but now the goal is running a command; learn how to turn a file read into execution."
excerpt: "Natas Level 32 — the same Perl file-reading trick is back, but now the goal is running a command; learn how to turn a file read into execution."
permalink: /docs/wargames/natas/natas32/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- natas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas32.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- natas
author: bamr87
nav_order: 32
sidebar_label: "Level 32"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas32
    URL:      http://natas32.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas32` and find the password for `natas33`.
</div>

### What this level teaches

Escalating from file read to command execution using the same Perl behaviour as Level 31.

### Key ideas

- **Same weakness, bigger prize.** The earlier trick shows what files can be named; this level needs a program that runs.
- **Environment.** The password is not readable directly; look at the directory contents and any helper programs left for you.
- **Chaining.** Several small steps (find the helper, run it, read the output) combine into the solution.

### How to approach it

1. Revisit your Level 31 approach and adapt it.
2. Explore the server using the file-read ability to understand what exists.
3. Look for something executable that returns what you need.

### How developers prevent it

As in the previous level, along with running web applications as users that cannot read other levels' secrets (least privilege).

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas31/">Level 31</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas33/">Level 33</a></nav>

</section>

<!-- study-guide:end -->
