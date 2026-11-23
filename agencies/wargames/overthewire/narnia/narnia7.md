---
title: "Narnia Level 7"
description: "Narnia Level 7 — a format-string bug again, this time used to redirect a function pointer."
excerpt: "Narnia Level 7 — a format-string bug again, this time used to redirect a function pointer."
permalink: /docs/wargames/narnia/narnia7/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia7.md
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
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia7`, find the password for `narnia8`.
</div>

### What this level teaches

Combining the format-string write primitive with a function pointer to change control flow.

### Key ideas

- **Function pointers** store the address of code to call. Changing one changes what runs.
- **Writing a precise value.** With `%n` and careful padding, you can write multi-byte values, sometimes in smaller pieces.
- **Reading the layout.** The addresses of the intended and unintended functions are printed or discoverable in the program.
- **Same technique, new goal.** You have already seen this idea in Level 5; here the target is different.

### How to approach it

1. Read the source and note how the pointer is set and used.
2. Find the addresses involved and the stack position of your input.
3. Build the format string, test with harmless values, then use the real ones.

### Why it matters

Writing a pointer is the usual first step to controlling a program, even in modern, hardened software.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia6/">Level 6</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
