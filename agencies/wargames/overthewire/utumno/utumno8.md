---
title: "Utumno Level 8"
description: "Utumno Level 8 — an intentionally undocumented final level, with a method for investigating it."
excerpt: "Utumno Level 8 — an intentionally undocumented final level, with a method for investigating it."
permalink: /docs/wargames/utumno/utumno8/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- utumno
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/utumno/utumno8.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- utumno
author: bamr87
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `utumno8`. The upstream index counts ten levels, but this mirror documents `utumno0` to `utumno8`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Utumno is a regular binary-exploitation wargame rescued from intruded.net. Its authors call it slightly harder than Behemoth and a lot harder than Leviathan.

### Where it fits

Utumno is rated 4/10 by its original authors, and lives under `/utumno/` on the game server (SSH port 2227). This is page 9 of 9 in this mirror. Final levels reward patience: break the problem into steps and test each one before chaining them.

### How to approach it

1. Start with `file` and `strings` on the level's program to learn what it is and what text it contains.
2. Check permissions with `ls -l`: a setuid or setgid bit tells you whose privileges the program runs with.
3. If you get stuck repeatedly, finish Behemoth first; the authors explicitly recommend it.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

### What to do next

- **Consolidate.** For each level, record the bug class, the tool that found it and the technique that worked.
- **Continue.** From the [games index](../../), Maze is a natural next step.
- **Read about defences.** Stack canaries, non-executable memory, ASLR and RELRO each map to attacks you have practised.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../utumno7/">Level 7</a><a class="sg-index" href="../">Utumno overview</a><span></span></nav>

</section>

<!-- study-guide:end -->
