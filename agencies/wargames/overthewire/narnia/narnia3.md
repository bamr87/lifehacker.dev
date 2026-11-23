---
title: "Narnia Level 3"
description: "Narnia Level 3 — another overflow level; use the source to see what an overflowing input can reach and plan around the program's file handling."
excerpt: "Narnia Level 3 — another overflow level; use the source to see what an overflowing input can reach and plan around the program's file handling."
permalink: /docs/wargames/narnia/narnia3/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia3.md
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
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia3`, find the password for `narnia4`.
</div>

### What this level teaches

Reasoning about stack layout and about what the program does with files, not only about return addresses.

### Key ideas

- **Read the source before debugging.** Note every buffer, its size, the variables declared near it and what the program does with them.
- **Not all overflows target return addresses.** Overwriting the right neighbouring variable can be easier and just as powerful.
- **Files as inputs and outputs.** When a program reads and writes files, think about what names you control and what links to other files you could create in a private `/tmp` directory.

### How to approach it

1. Draw the stack layout of the main function from the source.
2. Work out which variable your overflow reaches first and how the program uses it.
3. Test in `gdb`, then craft the file names or links needed.

### Why it matters

Real exploits are usually found by studying program behaviour, not by blindly overwriting return addresses.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia2/">Level 2</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
