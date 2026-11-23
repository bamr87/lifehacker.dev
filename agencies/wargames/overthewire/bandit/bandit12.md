---
title: "Bandit Level 12"
description: "Bandit Level 12 — undo a ROT13 substitution cipher with the tr command."
permalink: /docs/wargames/bandit/bandit12/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- bandit
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit12.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 12 — undo a ROT13 substitution cipher with the tr command."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 12
sidebar_label: "Level 12"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in the file **data.txt**, where all lowercase (a-z) and uppercase (A-Z) letters have been rotated by 13 positions

Commands you may need to solve this level
-----------------------------------------
grep, sort, uniq, strings, base64, tr, tar, gzip, bzip2, xxd

Helpful Reading Material
------------------------
- [Rot13 on Wikipedia][]

[Rot13 on Wikipedia]: https://en.wikipedia.org/wiki/ROT13

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit11`, find the password for `bandit12`.
</div>

### What this level teaches

Substitution ciphers, and character translation with `tr`.

### Key ideas

- **ROT13** replaces each letter by the one 13 places later in the alphabet, wrapping around. Because the alphabet has 26 letters, applying ROT13 twice returns the original, so the same operation encrypts and decrypts.
- **`tr SET1 SET2`** replaces each character of the first set with the corresponding character of the second. Ranges such as `a-e` are allowed, so `tr 'a-e' 'A-E'` upper-cases only those five letters.
- ROT13 is trivially reversible and provides obfuscation, not security.

### How to approach it

1. Work out by hand where `A` and `a` land after a 13-place shift, and write the two sets so every letter is covered.
2. Remember upper and lower case need their own ranges.
3. Test your `tr` command on a word you encode yourself before applying it to the real file.

### Why it matters

This is the first step of Krypton, where simple ciphers like this are attacked systematically with frequency analysis.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit11/">Level 11</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit13/">Level 13</a></nav>

</section>

<!-- study-guide:end -->
