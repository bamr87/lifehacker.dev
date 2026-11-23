---
title: "Drifter Level 15"
description: "Drifter Level 15 — \"Explosive decompression\": a level hinting at a decompression-related weakness."
excerpt: "Drifter Level 15 — \"Explosive decompression\": a level hinting at a decompression-related weakness."
permalink: /docs/wargames/drifter/drifter15/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter15.md
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
nav_order: 15
sidebar_label: "Level 15"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Explosive decompression :-)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 15 of 0–15, in the open-ended stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

The dangers of decompression code and of untrusted compressed data.

### Key ideas

- **The only hint.** The level is titled "Explosive decompression".
- **Why decompressors are risky.** They turn small inputs into large outputs, and bugs in size calculations can lead to overflows or resource exhaustion.
- **Careful analysis.** Identify the format, how output size is computed and what is trusted.

### How to approach it

1. Identify what is being decompressed and with what code.
2. Study the size and bounds handling.
3. Craft input that breaks an assumption.

### Why it matters

Decompression bugs have affected image libraries, archive tools and network protocols.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter14/">Level 14</a><a class="sg-index" href="../">Drifter overview</a><span></span></nav>

</section>

<!-- study-guide:end -->
