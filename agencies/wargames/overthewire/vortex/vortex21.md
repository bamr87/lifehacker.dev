---
title: "Vortex Level 21"
description: "Vortex Level 21 — a harder reverse-engineering task that may require understanding an encryptor."
excerpt: "Vortex Level 21 — a harder reverse-engineering task that may require understanding an encryptor."
permalink: /docs/wargames/vortex/vortex21/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex21.md
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
nav_order: 21
sidebar_label: "Level 21"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Reverse Me
----------
This level is a slightly more difficult reverse me (which might require understanding the encryptor for it).

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex21`, obtain access to `vortex22`.
</div>

### What this level teaches

Reverse engineering a program whose logic depends on an encryption routine.

### Key ideas

- **Understand the encryptor.** The page warns you may need to understand how it works.
- **Divide the program.** Separate the input handling, the transformation and the comparison.
- **Invert.** Once you know the transformation, work backwards from the target.

### How to approach it

1. Locate the encryption routine and describe it in pseudocode.
2. Write an equivalent function and test it against the binary's output.
3. Invert it to obtain the required input.

### Why it matters

Understanding custom crypto from binaries is a staple of malware analysis.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex20/">Level 20</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex22/">Level 22</a></nav>

</section>

<!-- study-guide:end -->
