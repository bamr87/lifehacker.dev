---
title: "Drifter Level 4"
description: "Drifter Level 4 — a binary that needs simple analysis, with a hint to keep resource limits in mind."
excerpt: "Drifter Level 4 — a binary that needs simple analysis, with a hint to keep resource limits in mind."
permalink: /docs/wargames/drifter/drifter4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level 4 is a binary requiring some simple analysis / reverse engineering.

Hint: Keep in mind about resource limits

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 4 of 0–15, in the analysis and logic stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Basic reverse engineering, and how process resource limits affect behaviour.

### Key ideas

- **Resource limits.** `ulimit` controls things like maximum file size, number of processes and core dump size. The hint says these matter to how the level behaves.
- **Simple analysis.** Disassemble the binary, find the check and understand what it needs.
- **Environment.** Anything you can change about how the program is launched may help.

### How to approach it

1. Run `file`, `strings`, `ltrace` and `strace` on the binary.
2. Read the relevant disassembly and note what limit-related calls it makes.
3. Adjust limits or input accordingly.

### Why it matters

Limits and environment variables are an under-appreciated part of the attack surface.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter3/">Level 3</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
