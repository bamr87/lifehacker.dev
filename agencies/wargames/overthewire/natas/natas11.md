---
title: "Natas Level 11"
description: "Natas Level 11 — a cookie is \"encrypted\" with repeating-key XOR; learn how a known plaintext reveals the key and lets you forge the cookie."
excerpt: "Natas Level 11 — a cookie is \"encrypted\" with repeating-key XOR; learn how a known plaintext reveals the key and lets you forge the cookie."
permalink: /docs/wargames/natas/natas11/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas11.md
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
nav_order: 11
sidebar_label: "Level 11"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas11
    URL:      http://natas11.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas11` and find the password for `natas12`.
</div>

### What this level teaches

How weak, home-made encryption fails against someone who knows part of the plaintext.

### Key ideas

- **XOR.** Combining two byte strings with exclusive-or is reversible: `(a XOR b) XOR b = a`.
- **Known-plaintext attack.** If you know the original data and see the encrypted result, XOR-ing them together reveals the key.
- **Repeating key.** A short key reused over a long message leaks quickly, as in Krypton's Vigenère levels.
- **Forgery.** Once you have the key, you can build your own valid cookie.

### How to approach it

1. Read the source to learn what data is stored in the cookie and how it is encoded.
2. Work out what plaintext the server started with and use it with the cookie value to recover the key.
3. Create the data you want, encrypt it the same way, and send it back.

### How developers prevent it

Never invent encryption. Use authenticated encryption from a trusted library, or keep state on the server and send only a random session ID.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas10/">Level 10</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas12/">Level 12</a></nav>

</section>

<!-- study-guide:end -->
