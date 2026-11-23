---
title: "Vortex Level 4"
description: "Vortex Level 4 — a common format-string bug guarded by a check on argc, which makes you think about how programs are started."
excerpt: "Vortex Level 4 — a common format-string bug guarded by a check on argc, which makes you think about how programs are started."
permalink: /docs/wargames/vortex/vortex4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

To exec or not to exec
----------------------
This is the common format string bug, exploit it with care though as a check is made with argc. What is the layout of a process's memory? How are programs executed?

Reading Material
----------------
- [Format String Technique][]
- [Exploiting Format String Vulnerabilities][]
- [Bypassing StackGuard and StackShield][]



[Format String Technique]: http://julianor.tripod.com/bc/NN-formats.txt
[Exploiting Format String Vulnerabilities]: http://julianor.tripod.com/bc/formatstring-1.2.pdf
[Bypassing StackGuard and StackShield]: http://www.phrack.org/issues.html?issue=56&id=5#article

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex4`, obtain access to `vortex5`.
</div>

### What this level teaches

Format-string exploitation under an unusual constraint.

### Key ideas

- **Format strings.** The page links papers on the technique, the classic guides to reading and writing memory with `printf`.
- **The `argc` check.** The program verifies the number of arguments, so you must find another way to deliver the format string and control execution.
- **Process memory layout.** The page asks: what is the layout of a process's memory, and how are programs executed? Environment variables, arguments and the loader all matter.
- **Executing programs.** `execve` lets you start a program with arbitrary argument and environment settings, including an unusual `argc`.

### How to approach it

1. Read the code and find where the format string comes from.
2. Work out how to start the program with the argument count and environment you need.
3. Use `gdb` to find the stack positions and build the write.

### Why it matters

Understanding how the kernel and loader hand a program its arguments helps in many exploitation scenarios.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex3/">Level 3</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
