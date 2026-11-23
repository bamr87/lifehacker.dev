---
title: "Narnia Level 4"
description: "Narnia Level 4 — a stack overflow where the environment has been cleared, so your injected code must live in the buffer itself."
excerpt: "Narnia Level 4 — a stack overflow where the environment has been cleared, so your injected code must live in the buffer itself."
permalink: /docs/wargames/narnia/narnia4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia4`, find the password for `narnia5`.
</div>

### What this level teaches

Adapting a familiar attack when a convenient hiding place is taken away.

### Key ideas

- **Where payload can live.** Earlier you may have used the environment; if the program wipes it, the buffer or arguments must hold your code.
- **Reliable addresses.** The stack position can shift with environment and argument size, so use `gdb`'s view and be consistent between debugging and real runs.
- **NOP sleds.** A run of no-operation instructions in front of shellcode widens the target you must hit.
- **Size limits.** Shellcode has to be small enough to fit.

### How to approach it

1. Read the source and find out what the program does to the environment.
2. Use `gdb` to find the offset and your buffer's address.
3. Build a payload of padding, shellcode and return address that fits.

### Why it matters

Practice in adapting to constraints is the core skill of exploit development.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia3/">Level 3</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
