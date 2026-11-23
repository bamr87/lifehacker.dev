---
title: "Leviathan Level 1"
description: "Leviathan Level 1 — watch a setuid program ask for a password and use ltrace to see what it compares your input to."
excerpt: "Leviathan Level 1 — watch a setuid program ask for a password and use ltrace to see what it compares your input to."
permalink: /docs/wargames/leviathan/leviathan1/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan1.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
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
**Level map:** logged in as `leviathan1`, find the password for `leviathan2`.
</div>

### What this level teaches

Dynamic analysis: running a program under a tracer instead of reading its code.

### Key ideas

- **Setuid.** The program runs with its owner's privileges, which is why it can reach files you cannot.
- **Library calls.** Compiled programs call functions such as `strcmp` to compare strings, and `ltrace` prints each call with its arguments.
- **Secrets in memory.** If the program compares your input with a hard-coded password, the tracer shows both strings.

### How to approach it

1. Run the program normally and see what it asks.
2. Run it again under `ltrace`, giving it some input, and read the comparisons it makes.
3. After you gain a shell, check which user you are with `id`.

### Why it matters

Tracing is a fast first step in malware analysis and debugging when you lack source code.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../leviathan0/">Level 0</a><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
