---
title: "Krypton Level 0"
description: "Krypton Level 0 — decode a Base64 string to log in, learning the difference between encoding and encryption."
excerpt: "Krypton Level 0 — decode a Base64 string to log in, learning the difference between encoding and encryption."
permalink: /docs/wargames/krypton/krypton0/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/krypton0.md
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
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Info
----------
Welcome to Krypton! The first level is easy. The following string encodes the password using Base64:

    S1JZUFRPTklTR1JFQVQ=

Use this password to log in to krypton.labs.overthewire.org with username krypton1 using SSH on port 2231. You can find the files for other levels in /krypton/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the page gives you the password for `krypton1` in encoded form.
</div>

### What this level teaches

Base64 is an encoding, not a cipher. Anyone can undo it.

### Key ideas

- **Encoding vs encryption.** Encoding changes representation for transport. Encryption uses a secret key so that only someone with the key can read the data.
- **Recognising Base64.** It uses letters, digits, `+` and `/`, and often ends with `=` padding.
- **Decoding tool.** The `base64` command with its decode option, or any programming language, reverses it.
- **SSH details.** The host and port in the level text are the ones you use for every Krypton level.

### How to approach it

1. Decode the string given in the page text.
2. Use the result as the password for the `krypton1` account on the stated host and port.
3. Look around `/krypton/` to see where each later level's files live.

### Why it matters

Tokens and credentials in Base64 are often mistaken for encrypted data. Treat the format as public.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Krypton overview</a><a class="sg-next" href="../krypton1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
