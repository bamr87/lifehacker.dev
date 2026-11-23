---
title: "Krypton Level 1"
description: "Krypton Level 1 — decrypt a rotation cipher, the simplest substitution cipher, using a one-line command."
excerpt: "Krypton Level 1 — decrypt a rotation cipher, the simplest substitution cipher, using a one-line command."
permalink: /docs/wargames/krypton/krypton1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/krypton1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Info
----------
The password for level 2 is in the file 'krypton2'. It is 'encrypted' using a simple rotation. It is also in non-standard ciphertext format. When using alpha characters for cipher text it is normal to group the letters into 5 letter clusters, regardless of word boundaries. This helps obfuscate any patterns. This file has kept the plain text word boundaries and carried them to the cipher text. Enjoy!

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `krypton1`, decrypt the file that holds the password for `krypton2`.
</div>

### What this level teaches

How a rotation cipher works and how to reverse it with the `tr` command.

### Key ideas

- **Rotation.** Each letter is shifted a fixed number of places along the alphabet. ROT13 shifts by 13, which is self-inverse.
- **Keeping word boundaries.** The page notes that the usual five-letter grouping has not been used here, so the ciphertext keeps the spaces of the original text.
- **`tr`.** Translates one set of characters into another, as in Bandit Level 12. Work out the mapping for both upper and lower case.

### How to approach it

1. Read the ciphertext and note that it has the shape of ordinary text.
2. Build the `tr` sets that undo the rotation described in the page.
3. Test on a short word you encode yourself.

### Why it matters

Rotation ciphers are weak because there is nothing secret: the algorithm is the key. The same flaw reappears in less obvious forms.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../krypton0/">Level 0</a><a class="sg-index" href="../">Krypton overview</a><a class="sg-next" href="../krypton2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
