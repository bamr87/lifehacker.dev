---
title: "Vortex Level 15"
description: "Vortex Level 15 — decrypt an encrypted file using reverse engineering and cryptanalysis, helped by the fact the password is eight uppercase letters."
excerpt: "Vortex Level 15 — decrypt an encrypted file using reverse engineering and cryptanalysis, helped by the fact the password is eight uppercase letters."
permalink: /docs/wargames/vortex/vortex15/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex15.md
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
nav_order: 15
sidebar_label: "Level 15"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Weak Encryption
---------------
You have found an encrypted file, decrypt it (some reversing, crypt and general analysis needed, and if you're lazy, the password is 8-bytes long and contains values between A and Z). You must login to [vortex.labs.overthewire.org][] to complete this level.

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex15`, obtain access to `vortex16`.
</div>

### What this level teaches

Combining reverse engineering with cryptanalysis.

### Key ideas

- **Know the key space.** If the password is 8 bytes between A and Z, there are 26 to the power 8 (about 209 billion) possibilities, large but structured.
- **Find the algorithm.** Reverse the program that encrypted the file to see how the key is used.
- **Exploit structure.** Weak ciphers leak information, so you may recover the key piece by piece rather than guess all of it.

### How to approach it

1. Reverse the encryption routine.
2. Look for weaknesses in how the key is applied.
3. Recover the key and decrypt the file.

### Why it matters

Many proprietary file protections are weak. Knowing how to analyse them shows why standard, reviewed algorithms are essential.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex14/">Level 14</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex16/">Level 16</a></nav>

</section>

<!-- study-guide:end -->
