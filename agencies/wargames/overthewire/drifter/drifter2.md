---
title: "Drifter Level 2"
description: "Drifter Level 2 — a simple stack overflow whose side effects get in the way of debugging and of launching a program directly with execve."
excerpt: "Drifter Level 2 — a simple stack overflow whose side effects get in the way of debugging and of launching a program directly with execve."
permalink: /docs/wargames/drifter/drifter2/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- drifter
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter2.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- drifter
author: bamr87
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Simple stack overflow, but with a side effect that affects debugging, and executing problems. Keep in mind that a straight execve() will not work, due to kernel issuing a breakpoint.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 2 of 0–15, in the memory corruption stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

How an apparently simple exploit can be complicated by the environment.

### Key ideas

- **Simple bug.** The page describes a simple stack overflow.
- **Side effect on debugging.** Something about how the program runs affects how you can debug it, so work out an alternative debugging method.
- **The execve warning.** A straight `execve()` call will not work because the kernel issues a breakpoint; your payload must start a shell by another route.
- **Think about the platform.** Behaviour that differs from earlier levels is the clue.

### How to approach it

1. Reproduce the crash and find the offset.
2. Identify exactly what stops your usual payload from working.
3. Adjust the payload until the program does what you want.

### Why it matters

Real targets have quirks that break textbook exploits, and diagnosing them is half the job.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter1/">Level 1</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
