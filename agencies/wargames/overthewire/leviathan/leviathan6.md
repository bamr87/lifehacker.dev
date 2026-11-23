---
title: "Leviathan Level 6"
description: "Leviathan Level 6 — a program wants a four-digit code; learn to brute-force a small secret with a shell loop."
excerpt: "Leviathan Level 6 — a program wants a four-digit code; learn to brute-force a small secret with a shell loop."
permalink: /docs/wargames/leviathan/leviathan6/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan6.md
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
nav_order: 6
sidebar_label: "Level 6"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `leviathan6`, find the password for `leviathan7`.
</div>

### What this level teaches

Automating a guessing attack on a small search space.

### Key ideas

- **Search space.** A four-digit code has only 10,000 possibilities.
- **Loops.** A `for` loop with `seq` and `printf` can generate every candidate, including leading zeros.
- **Detecting success.** The program behaves differently on a wrong and a right code, so your loop can stop when the output changes.

### How to approach it

1. Run the program once by hand to learn its arguments and failure behaviour.
2. Write a loop that tries each value and prints only the interesting result.

### Why it matters

It shows why short numeric codes need rate limiting, and gives you practice with shell automation for later games.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../leviathan5/">Level 5</a><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan7/">Level 7</a></nav>

</section>

<!-- study-guide:end -->
