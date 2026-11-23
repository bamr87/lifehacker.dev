---
title: "Narnia Level 2"
description: "Narnia Level 2 — a classic stack buffer overflow where you overwrite the saved return address to take control of execution."
excerpt: "Narnia Level 2 — a classic stack buffer overflow where you overwrite the saved return address to take control of execution."
permalink: /docs/wargames/narnia/narnia2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia2.md
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
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia2`, find the password for `narnia3`.
</div>

### What this level teaches

The textbook "smash the stack" attack.

### Key ideas

- **Stack frame.** Each function call stores its locals, a saved frame pointer and a return address.
- **Control flow hijack.** Overwriting the return address makes the function return to a place you choose instead of its caller.
- **Finding the offset.** A cyclic pattern in `gdb` or `pwntools` shows exactly how many bytes are needed to reach the return address.
- **Where to jump.** Into your own shellcode, whose address you must find reliably.
- **Reading material.** "Smashing the Stack for Fun and Profit" is the classic paper.

### How to approach it

1. Read the source and note the buffer size and the unsafe copy.
2. In `gdb`, crash the program with a pattern to find the offset.
3. Place shellcode where you can predict its address and aim the return address at it.

### Why it matters

Understanding this attack explains stack canaries, non-executable stacks and address randomisation, all of which exist to stop it.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia1/">Level 1</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
