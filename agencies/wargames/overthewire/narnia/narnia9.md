---
title: "Narnia Level 9"
description: "Narnia Level 9 — the final Narnia page in this mirror; apply everything from Levels 0–8 and consolidate your exploitation skills."
excerpt: "Narnia Level 9 — the final Narnia page in this mirror; apply everything from Levels 0–8 and consolidate your exploitation skills."
permalink: /docs/wargames/narnia/narnia9/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia9.md
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
nav_order: 9
sidebar_label: "Level 9"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia9`. This is the highest-numbered Narnia page; the upstream index counts ten levels, `narnia0` to `narnia9`.
</div>

### What this level teaches

Putting the whole Narnia toolbox together without a hint about which technique to use.

### Key ideas

- **Diagnose before attacking.** Read the source, identify the unsafe operation, and decide whether you are looking at an overflow, a format string, a pointer problem or something else.
- **Use all your tools.** `gdb` for layout, `objdump` or `ghidra` for the compiled view, and a short script for building payloads.
- **Check what the goal is.** As in earlier levels, the program is setuid to another user; reading that user's file under `/etc/narnia_pass/` is the objective.

### How to approach it

1. Read the source carefully and annotate it.
2. Reproduce a crash or unexpected behaviour before writing any exploit.
3. Build the payload in small, tested steps.

### What to do next

- **Re-derive one earlier exploit from scratch** using only the source and `gdb`.
- **Move on to Behemoth.** From the [games index](../../), Behemoth is the next step; it does not hand you source code.
- **Learn the defences.** Read about stack canaries, non-executable memory and address randomisation to see why today's exploits are harder.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia8/">Level 8</a><a class="sg-index" href="../">Narnia overview</a><span></span></nav>

</section>

<!-- study-guide:end -->
