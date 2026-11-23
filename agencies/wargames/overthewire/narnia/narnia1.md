---
title: "Narnia Level 1"
description: "Narnia Level 1 — the program runs code taken from an environment variable; learn what shellcode is and how to supply it."
excerpt: "Narnia Level 1 — the program runs code taken from an environment variable; learn what shellcode is and how to supply it."
permalink: /docs/wargames/narnia/narnia1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia1`, find the password for `narnia2`.
</div>

### What this level teaches

How executable code can be delivered through an environment variable, and what shellcode is.

### Key ideas

- **Environment variables** are strings the shell passes to every program. Programs can read them and they can be arbitrarily set by the user.
- **Shellcode** is machine code written to perform an action such as starting a shell. It must avoid bytes that break copying or printing.
- **Function pointers.** The program treats the variable's contents as a function and jumps to it.
- **Match the architecture.** Shellcode is specific to the CPU and word size; check what the binary is with `file`.

### How to approach it

1. Read the source to see which variable is read and what is done with it.
2. Obtain or write shellcode for the correct architecture and place it in that variable, ensuring bytes survive the shell.
3. Run the program and observe which user you become.

### Why it matters

It is the cleanest demonstration of why executing data as code is dangerous, and why modern systems mark data memory as non-executable.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia0/">Level 0</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
