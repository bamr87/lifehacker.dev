---
title: "Drifter Level 10"
description: "Drifter Level 10 — additional practice with a non-executable stack, relying on careful reverse engineering."
excerpt: "Drifter Level 10 — additional practice with a non-executable stack, relying on careful reverse engineering."
permalink: /docs/wargames/drifter/drifter10/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter10.md
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
nav_order: 10
sidebar_label: "Level 10"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

If you're not a pro at this stuff yet, here's some additional practice. Beware of the nonexec stack. Go go power reverser.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 10 of 0–15, in the privileges and practice stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Exploiting a program when the stack is non-executable.

### Key ideas

- **NX stack.** Injected shellcode on the stack will not run.
- **Reuse existing code.** Return-to-libc or ROP chains replace shellcode.
- **Power reversing.** The page urges you to reverse the program thoroughly to find what you can reuse.

### How to approach it

1. Confirm the stack protection and locate the vulnerability.
2. Identify useful functions and gadgets.
3. Build and test the chain in `gdb`.

### Why it matters

Practice with non-executable memory is practice with the modern default.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter9/">Level 9</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter11/">Level 11</a></nav>

</section>

<!-- study-guide:end -->
