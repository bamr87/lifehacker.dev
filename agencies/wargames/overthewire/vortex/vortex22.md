---
title: "Vortex Level 22"
description: "Vortex Level 22 — another key-generation level, this time with object files available in /vortex to analyse."
excerpt: "Vortex Level 22 — another key-generation level, this time with object files available in /vortex to analyse."
permalink: /docs/wargames/vortex/vortex22/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex22.md
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
nav_order: 22
sidebar_label: "Level 22"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Object Analysis
---------------
This is another keygen level. You might want to check "/vortex/vortex22\_\*.o" for some object files.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex22`, obtain access to `vortex23`.
</div>

### What this level teaches

Using object files to understand a program's pieces.

### Key ideas

- **Object files** (`.o`) contain compiled code and symbols before linking, so they often have more names than the final binary.
- **Where to look.** The page points to files matching `/vortex/vortex22_*.o`.
- **Keygen again.** Replicate the validation, then produce valid input.

### How to approach it

1. Inspect the object files with `objdump -d` and `nm`.
2. Rebuild the logic of the check.
3. Write a generator and test it on the real program.

### Why it matters

Intermediate build artefacts can leak much more than a stripped final binary.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex21/">Level 21</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex23/">Level 23</a></nav>

</section>

<!-- study-guide:end -->
