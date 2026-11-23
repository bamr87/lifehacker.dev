---
title: "Leviathan Level 4"
description: "Leviathan Level 4 — find a program whose output is a string of binary digits and learn to convert numbers between bases."
excerpt: "Leviathan Level 4 — find a program whose output is a string of binary digits and learn to convert numbers between bases."
permalink: /docs/wargames/leviathan/leviathan4/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan4.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
author: bamr87
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `leviathan4`, find the password for `leviathan5`.
</div>

### What this level teaches

Number bases and text encoding, plus another round of careful directory exploration.

### Key ideas

- **Binary and ASCII.** Each character is stored as a number (an ASCII code); written in binary, a byte is eight digits.
- **Conversion by tool or by hand.** A short script or a calculator can turn groups of eight bits into characters.
- **Hidden places.** Remember what a full directory listing shows that a default one does not.

### How to approach it

1. List everything in your home directory and run what you find there.
2. Look at the output as groups of eight digits and convert each group to the character it represents.

### Why it matters

Reading binary, hexadecimal and ASCII fluently makes all later binary-exploitation work easier.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../leviathan3/">Level 3</a><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
