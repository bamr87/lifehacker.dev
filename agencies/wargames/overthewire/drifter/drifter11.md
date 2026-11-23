---
title: "Drifter Level 11"
description: "Drifter Level 11 — the executable base and the stack are randomised, so you must defeat ASLR to get code execution."
excerpt: "Drifter Level 11 — the executable base and the stack are randomised, so you must defeat ASLR to get code execution."
permalink: /docs/wargames/drifter/drifter11/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter11.md
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
nav_order: 11
sidebar_label: "Level 11"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

This level randomizes the executable base and stack -- can you beat the randomisation to get code execution?

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 11 of 0–15, in the randomisation and reversing stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Address space layout randomisation and how to work around it.

### Key ideas

- **What is randomised.** The page says both the executable's base address and the stack move on each run.
- **Information leaks.** A leaked pointer gives you the layout for that run.
- **Relative addressing.** Offsets between things in the same module do not change, even if their base does.
- **Brute force.** On a 32-bit system, the entropy may be small enough to guess.

### How to approach it

1. Run the program several times and record which addresses change.
2. Look for a leak or a part of the layout that stays fixed.
3. Build an exploit that is robust to the randomness.

### Why it matters

ASLR is one of the main defences in use, and bypasses are routine in real exploit chains.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter10/">Level 10</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter12/">Level 12</a></nav>

</section>

<!-- study-guide:end -->
