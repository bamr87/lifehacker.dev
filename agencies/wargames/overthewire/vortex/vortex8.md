---
title: "Vortex Level 8"
description: "Vortex Level 8 — a simple reverse-engineering task: disassemble a dynamically linked executable and work out what it wants."
excerpt: "Vortex Level 8 — a simple reverse-engineering task: disassemble a dynamically linked executable and work out what it wants."
permalink: /docs/wargames/vortex/vortex8/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex8.md
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
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Some simple reverse engineering
-------------------------------
Disassemble this dynamically linked executable.

Reading Material
----------------
- [Reverse Engineering][]

[Reverse Engineering]: https://web.archive.org/web/20160315083251/http://althing.cs.dartmouth.edu/local/www.acm.uiuc.edu/sigmil/RevEng/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex8`, obtain access to `vortex9`.
</div>

### What this level teaches

Static analysis of a small dynamically linked program.

### Key ideas

- **Dynamic linking.** Library calls go through the procedure linkage table; tools like `ltrace` show them at run time.
- **Static plus dynamic.** Read the disassembly and confirm your reading by running the program under a tracer or debugger.
- **Reading.** The page links a reverse-engineering primer.

### How to approach it

1. Run `file`, `strings` and `ltrace` to form a first impression.
2. Disassemble `main` and follow the control flow to the success path.
3. Work out the input that reaches it.

### Why it matters

Small reversing tasks build the pattern recognition used for every larger binary you will face.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex7/">Level 7</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
