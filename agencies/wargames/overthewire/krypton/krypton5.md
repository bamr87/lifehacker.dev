---
title: "Krypton Level 5"
description: "Krypton Level 5 — break a Vigenère cipher when the key length is unknown, by first discovering the length from patterns in the ciphertext."
excerpt: "Krypton Level 5 — break a Vigenère cipher when the key length is unknown, by first discovering the length from patterns in the ciphertext."
permalink: /docs/wargames/krypton/krypton5/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- krypton
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/krypton5.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- krypton
author: bamr87
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Info
----------

FA can break a known key length as well. Lets try one last polyalphabetic cipher, but this time the key length is unknown. Note: the text is writen in American English

Enjoy.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `krypton5`, decrypt the file that holds the password for `krypton6`.
</div>

### What this level teaches

How to find an unknown key length, then reuse the Level 4 method.

### Key ideas

- **Repeated sequences (Kasiski examination).** If the same plaintext fragment is encrypted at positions separated by a multiple of the key length, it produces the same ciphertext. Distances between repeats suggest the length.
- **Index of coincidence.** A statistic measuring how uneven the letter distribution is. When you split text by the correct key length, each group looks like English and the statistic jumps.
- **Try lengths systematically.** A short script that computes the statistic for lengths 1 to about 20 is quick to write.
- **Then proceed as before** with frequency analysis for each position.

### How to approach it

1. Look for repeated sequences and note their spacing, or compute the coincidence statistic.
2. Pick the most plausible key length.
3. Apply the method from Level 4.

### Why it matters

Key-length discovery generalises to many attacks on reused keys, including repeating-key XOR, which you will meet again.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../krypton4/">Level 4</a><a class="sg-index" href="../">Krypton overview</a><a class="sg-next" href="../krypton6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
