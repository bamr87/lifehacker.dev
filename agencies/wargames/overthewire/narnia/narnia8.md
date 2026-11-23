---
title: "Narnia Level 8"
description: "Narnia Level 8 — a later Narnia level that combines the earlier techniques; use the source and a debugger to find where your input goes."
excerpt: "Narnia Level 8 — a later Narnia level that combines the earlier techniques; use the source and a debugger to find where your input goes."
permalink: /docs/wargames/narnia/narnia8/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- narnia
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia8.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- narnia
author: bamr87
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia8`, find the password for `narnia9`.
</div>

### What this level teaches

Choosing the right technique yourself, after seeing several in earlier levels.

### Key ideas

- **Diagnose first.** Ask which memory-safety bug is present before choosing an attack.
- **Use the debugger.** `gdb` shows registers, the stack and memory around your input, which is faster than guessing.
- **Pointer-based bugs.** Programs that copy data through pointers may let a small mistake in one place write somewhere unexpected.
- **Keep notes.** By now you have a toolbox; write which tool fits which symptom.

### How to approach it

1. Read the source twice, slowly, and annotate every pointer and buffer.
2. Run it under `gdb` with normal input and note what lives where.
3. Change one thing at a time until the program does something it should not.

### Why it matters

Real vulnerability hunting is exactly this: reading code and choosing the right primitive.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia7/">Level 7</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
