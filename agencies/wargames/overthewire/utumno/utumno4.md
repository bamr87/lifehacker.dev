---
title: "Utumno Level 4"
description: "Utumno Level 4 — an intentionally undocumented mid-game level, with a method for investigating it."
excerpt: "Utumno Level 4 — an intentionally undocumented mid-game level, with a method for investigating it."
permalink: /docs/wargames/utumno/utumno4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/utumno/utumno4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `utumno4`, find the password for `utumno5`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Utumno is a regular binary-exploitation wargame rescued from intruded.net. Its authors call it slightly harder than Behemoth and a lot harder than Leviathan.

### Where it fits

Utumno is rated 4/10 by its original authors, and lives under `/utumno/` on the game server (SSH port 2227). This is page 5 of 9 in this mirror. Mid-game levels in wargames like this often add constraints that break the textbook technique, such as filtered bytes or a cleared environment, so be ready to adapt.

### How to approach it

1. Note the architecture and which protections are active (`file`, `readelf -l`), so you know which techniques are possible.
2. List what the program trusts: input length, file names, the environment, the current directory, the time.
3. If you get stuck repeatedly, finish Behemoth first; the authors explicitly recommend it.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../utumno3/">Level 3</a><a class="sg-index" href="../">Utumno overview</a><a class="sg-next" href="../utumno5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
