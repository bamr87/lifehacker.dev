---
title: "Behemoth Level 4"
description: "Behemoth Level 4 — a program reads a file whose name depends on its process ID, which opens the door to a race condition using symbolic links."
excerpt: "Behemoth Level 4 — a program reads a file whose name depends on its process ID, which opens the door to a race condition using symbolic links."
permalink: /docs/wargames/behemoth/behemoth4/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- behemoth
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/behemoth/behemoth4.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- behemoth
author: bamr87
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `behemoth4`, find the password for `behemoth5`.
</div>

### What this level teaches

Race conditions and predictable file names.

### Key ideas

- **Predictable names.** A file path derived from a value you can learn, such as the process ID, is predictable.
- **Time window.** The program pauses between steps, which gives you time to change what a path points at.
- **Symbolic links.** A link at the expected path can make the privileged program read a file it was never meant to show you.
- **Controlling the process.** Job control or signals (`kill -STOP`) let you pause a process so you can prepare the link.

### How to approach it

1. Use `strace` to find which path the program opens and how it names it.
2. Work out how to learn the process ID early and arrange for the right file to exist.
3. Repeat until the timing works.

### Why it matters

Time-of-check to time-of-use bugs are a major real-world class, which is why secure temporary-file functions exist.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../behemoth3/">Level 3</a><a class="sg-index" href="../">Behemoth overview</a><a class="sg-next" href="../behemoth5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
