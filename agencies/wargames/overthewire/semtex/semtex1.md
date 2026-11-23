---
title: "Semtex Level 1"
description: "Semtex Level 1 — reverse engineer a simple encryption tool and decrypt a given ciphertext."
excerpt: "Semtex Level 1 — reverse engineer a simple encryption tool and decrypt a given ciphertext."
permalink: /docs/wargames/semtex/semtex1/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- semtex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex1.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- semtex
author: bamr87
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Simple encryption
-----------------
A password has been crypted using the /semtex/semtex1 tool. The crypted password is HRXDZNWEAWWCP. You have to reverse engineer the algorithm and decrypt the password. You might try the -v switch for encrypt.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the goal is to decrypt the password shown on the page, which was produced by `/semtex/semtex1`.
</div>

### What this level teaches

Working out an encryption algorithm by experiment and by reading the program.

### Key ideas

- **Black-box analysis.** The page notes the tool has a `-v` switch for encryption. Feed it simple inputs and watch the output.
- **Look for structure.** Does the same letter always encrypt the same way? Does position matter? Does the output length match?
- **Invert it.** Once you understand the transformation you can write the reverse.
- **Reading code.** Disassembly can confirm your hypothesis.

### How to approach it

1. Run the tool with inputs like all `A`s, a single changed letter and different lengths.
2. Formulate a rule and test predictions.
3. Apply the inverse to the ciphertext on the page.

### Why it matters

It is the same method used to break many home-made ciphers.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex0/">Level 0</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
