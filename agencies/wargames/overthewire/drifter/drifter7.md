---
title: "Drifter Level 7"
description: "Drifter Level 7 — \"Gentleman, start your disassemblers\": a reverse-engineering level with IDA recommended."
excerpt: "Drifter Level 7 — \"Gentleman, start your disassemblers\": a reverse-engineering level with IDA recommended."
permalink: /docs/wargames/drifter/drifter7/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter7.md
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
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Gentleman, start your disassemblers

**Material:**

[IDA Pro Freeware][]

[IDA Pro Demo][]

  [IDA Pro Freeware]: http://www.hex-rays.com/idapro/idadownfreeware.htm
  [IDA Pro Demo]: http://www.hex-rays.com/idapro/idadowndemo.htm

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 7 of 0–15, in the remote daemons stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Using a disassembler to understand a program.

### Key ideas

- **Disassembler.** The page links IDA Pro Freeware and a demo. Ghidra is a free alternative.
- **Method.** Identify entry points, strings and library calls first, then follow interesting paths.
- **Annotate.** Rename functions and variables as you understand them.

### How to approach it

1. Load the binary, list strings and imports.
2. Trace from input to decision.
3. Confirm your reading by running it with chosen inputs.

### Why it matters

Reverse-engineering fluency is the skill that unlocks the rest of the game.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter6/">Level 6</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
