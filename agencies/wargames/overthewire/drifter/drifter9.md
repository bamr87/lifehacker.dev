---
title: "Drifter Level 9"
description: "Drifter Level 9 — escalate privileges by working out a secret file format and exploiting security oversights."
excerpt: "Drifter Level 9 — escalate privileges by working out a secret file format and exploiting security oversights."
permalink: /docs/wargames/drifter/drifter9/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- drifter
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter9.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- drifter
author: bamr87
nav_order: 9
sidebar_label: "Level 9"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Get ready to escalate those privileges. You'll have to work out a secret file format and attack some security oversights.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 9 of 0–15, in the privileges and practice stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Local privilege escalation by combining format knowledge and configuration mistakes.

### Key ideas

- **Reverse the format.** The program uses a file format that is not documented; you derive it from the code and examples.
- **Security oversights.** The weakness is not a single memory bug but mistakes in how the program trusts files and permissions.
- **Enumerate.** Look at permissions, ownership and what the program reads and writes.

### How to approach it

1. Trace the program to see which files it opens.
2. Work out the format from the parsing code.
3. Build a file that makes the program do something it should not.

### Why it matters

Most real privilege escalations come from trust mistakes rather than exotic bugs.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter8/">Level 8</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter10/">Level 10</a></nav>

</section>

<!-- study-guide:end -->
