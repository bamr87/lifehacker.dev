---
title: "Vortex Level 5"
description: "Vortex Level 5 — brute-force an MD5 search space, and learn why shortening a password makes the attack feasible."
excerpt: "Vortex Level 5 — brute-force an MD5 search space, and learn why shortening a password makes the attack feasible."
permalink: /docs/wargames/vortex/vortex5/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex5.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

MD5 Brute Force
---------------
A password is required for the next level. vortex5.c and md5.h. a-z,A-Z,0-9 is the search space. The password length is 5 chars long, it was originally 7 chars long.

    Collision(s) tested : 489265082 in 217 second(s), 361 millisec, 101 microsec.
    Average of 2250932.1 hashes/sec.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex5`, obtain access to `vortex6`.
</div>

### What this level teaches

How big search spaces are, and how speed (hashes per second) decides what is feasible.

### Key ideas

- **Search space.** Letters and digits (a–z, A–Z, 0–9) give 62 choices per position. A five-character password has 62 to the power 5, about 916 million possibilities.
- **Throughput.** The page records a run of roughly 2.25 million hashes per second. At that speed five characters take a few minutes, while the original seven characters (about 3.5 trillion possibilities) would take weeks on that hardware.
- **Provided source.** The code and `md5.h` are available; you are expected to write or adapt a search.
- **Optimise.** Fast hashing loops in C, multiple cores or GPUs, and early rejection all change the arithmetic.

### How to approach it

1. Read the source to learn exactly what is hashed and what you must match.
2. Write an efficient search in C, and test it on a small known case first.
3. Estimate the time before launching the full run.

### Why it matters

It explains why password length and slow hashes (bcrypt, scrypt, Argon2) matter, and why fast hashes such as MD5 are poor for storing passwords.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex4/">Level 4</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
