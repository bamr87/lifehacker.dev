---
title: "Utumno Level 0"
description: "Utumno Level 0 — an intentionally undocumented first level, with a method for investigating it."
excerpt: "Utumno Level 0 — an intentionally undocumented first level, with a method for investigating it."
permalink: /docs/wargames/utumno/utumno0/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/utumno/utumno0.md
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
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `utumno0`, find the password for `utumno1`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Utumno is a regular binary-exploitation wargame rescued from intruded.net. Its authors call it slightly harder than Behemoth and a lot harder than Leviathan.

### Where it fits

Utumno is rated 4/10 by its original authors, and lives under `/utumno/` on the game server (SSH port 2227). This is page 1 of 9 in this mirror. Treat the first level as orientation: learn the account layout, the data directory and the tools available before looking for a bug.

### How to approach it

1. Start with `file` and `strings` on the level's program to learn what it is and what text it contains.
2. Check permissions with `ls -l`: a setuid or setgid bit tells you whose privileges the program runs with.
3. If you get stuck repeatedly, finish Behemoth first; the authors explicitly recommend it.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Utumno overview</a><a class="sg-next" href="../utumno1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
