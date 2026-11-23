---
title: "Vortex Level 7"
description: "Vortex Level 7 — find input whose CRC-32 checksum equals a given value, learning that CRCs are not cryptographic hashes."
excerpt: "Vortex Level 7 — find input whose CRC-32 checksum equals a given value, learning that CRCs are not cryptographic hashes."
permalink: /docs/wargames/vortex/vortex7/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex7.md
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
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Checksum Fun
------------
This level requires CRC\_32(argv[1], strlen(argv[1])) to be 0xe1ca95ee. You might need to extract the crc tables from the program.

Reading Material
----------------
- [CRC and How to Reverse It][]
- [CRC and How to Reverse It (mirror)]



[CRC and How to Reverse It]: http://www.woodmann.com/fravia/crctut1.htm
[CRC and How to Reverse It (mirror)]: http://taz.newffr.com/TAZ/Reverse_Engineering/CRC.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex7`, obtain access to `vortex8`.
</div>

### What this level teaches

How CRC checksums work and why they can be forged.

### Key ideas

- **The requirement.** The CRC-32 of the program's first argument must equal a specific 32-bit value shown on the page.
- **CRC tables.** The program uses a lookup table you may need to extract from the binary.
- **Linearity.** CRCs are linear over a finite field, so you can compute bytes that force any result, which is impossible with a proper cryptographic hash.
- **Reading.** "CRC and How to Reverse It" is linked.

### How to approach it

1. Learn how a table-driven CRC-32 is computed.
2. Choose how many free bytes you will append or choose and solve for them.
3. Verify your answer with an independent CRC implementation.

### Why it matters

CRCs detect accidental errors, not tampering. Never use them for integrity against an attacker.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex6/">Level 6</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
