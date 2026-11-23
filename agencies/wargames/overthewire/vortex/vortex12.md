---
title: "Vortex Level 12"
description: "Vortex Level 12 — exploit a program knowing the stack is not executable, which rules out classic shellcode on the stack."
excerpt: "Vortex Level 12 — exploit a program knowing the stack is not executable, which rules out classic shellcode on the stack."
permalink: /docs/wargames/vortex/vortex12/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex12.md
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
nav_order: 12
sidebar_label: "Level 12"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

We don't want no executable stack
---------------------------------
Exploit this level knowing that the stack is not executable. You must login to [vortex.labs.overthewire.org][] to complete this level..

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex12`, obtain access to `vortex13`.
</div>

### What this level teaches

Defeating the non-executable stack.

### Key ideas

- **NX stack.** The CPU refuses to run code placed on the stack, so injected shellcode will not work.
- **Alternatives.** Reuse existing code (return-to-libc) or chain short code fragments (return-oriented programming).
- **Library locations.** Use `ldd` and `gdb` to find functions and strings in loaded libraries.
- **Login required.** The page says you must log in to the Vortex host to complete this level.

### How to approach it

1. Confirm the stack is non-executable and read the vulnerable code.
2. Pick a function in the C library that does what you need, and find the address of a string for its argument.
3. Lay out the stack frame as the function expects.

### Why it matters

Non-executable memory is standard today, so ret2libc and ROP are the baseline techniques.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex11/">Level 11</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex13/">Level 13</a></nav>

</section>

<!-- study-guide:end -->
