---
title: "Vortex Level 1"
description: "Vortex Level 1 — a buffer overflow must set a pointer to a specific value, with a hint about how bash handles end of file."
excerpt: "Vortex Level 1 — a buffer overflow must set a pointer to a specific value, with a hint about how bash handles end of file."
permalink: /docs/wargames/vortex/vortex1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Canary Values
-------------
We are looking for a specific value in ptr. You may need to consider how bash handles EOF..

Reading Material
----------------
- [Smashing the Stack for Fun and Profit][]
- [Smashing The Modern Stack For Fun And Profit][]



[Smashing the Stack for Fun and Profit]: http://www.phrack.com/issues/49/14.html#article
[Smashing The Modern Stack For Fun And Profit]: https://www.exploit-db.com/papers/13162/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex1`, obtain access to `vortex2`.
</div>

### What this level teaches

How to overwrite a specific value in memory and how shell input handling can interfere with doing so.

### Key ideas

- **Target value.** The page says you are looking for a particular value in `ptr`, a variable you must overwrite precisely.
- **Canary values.** The level title refers to a value placed to detect overflows, and to what it takes to preserve or satisfy it.
- **Shell and EOF.** The page hints that how bash treats end-of-file matters to your input. Pipelines, here-strings and reading from files may behave differently.
- **Reading.** "Smashing the Stack for Fun and Profit" and its modern follow-up are linked.

### How to approach it

1. Read the source and compute how many bytes separate the buffer from `ptr`.
2. Build the exact bytes with a script, mindful of endianness.
3. If the program reads input oddly, test how your input arrives.

### Why it matters

It trains you to control memory byte by byte, and to debug the delivery mechanism as well as the payload.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex0/">Level 0</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
