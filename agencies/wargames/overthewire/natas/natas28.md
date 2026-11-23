---
title: "Natas Level 28"
description: "Natas Level 28 — a query is encrypted with AES in ECB mode; learn how block-by-block encryption lets an attacker cut and paste ciphertext."
excerpt: "Natas Level 28 — a query is encrypted with AES in ECB mode; learn how block-by-block encryption lets an attacker cut and paste ciphertext."
permalink: /docs/wargames/natas/natas28/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- natas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas28.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- natas
author: bamr87
nav_order: 28
sidebar_label: "Level 28"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas28
    URL:      http://natas28.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas28` and find the password for `natas29`.
</div>

### What this level teaches

An encryption oracle attack against ECB mode.

### Key ideas

- **ECB mode.** Each block of 16 bytes is encrypted independently, so identical plaintext blocks give identical ciphertext blocks and blocks can be rearranged.
- **Oracle.** The application encrypts text you submit, which you can study.
- **Finding the block boundaries.** Submitting repeated input and watching where the ciphertext starts to repeat reveals how the application's own text is laid out.
- **Cut and paste.** You can build a ciphertext containing the plaintext you want by assembling blocks from different requests.

### How to approach it

1. Submit inputs of increasing length and watch the output length and repeating patterns.
2. Work out the unknown prefix and suffix the server adds.
3. Craft input so that a block you control contains the SQL you want, then reuse it.

### How developers prevent it

Use authenticated encryption such as AES-GCM, and do not construct SQL from decrypted data.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas27/">Level 27</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas29/">Level 29</a></nav>

</section>

<!-- study-guide:end -->
