---
title: "Manpage Level 7"
description: "Manpage Level 7 — an intentionally undocumented final level, with a method for investigating it."
excerpt: "Manpage Level 7 — an intentionally undocumented final level, with a method for investigating it."
permalink: /docs/wargames/manpage/manpage7/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- manpage
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/manpage/manpage7.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- manpage
author: bamr87
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `manpage7`. This is the highest-numbered Manpage page in this mirror (`manpage7`).
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Manpage is about breaking common Linux C-programming misconceptions. Its author's advice is that a good way to begin auditing code is to read the manual pages for pitfalls and unusual behaviour.

### Where it fits

Manpage is given only as x/10 in its original description, so effectively unrated, and lives under `/manpage/` on the game server (SSH port 2224). This is page 8 of 8 in this mirror. Final levels reward patience: break the problem into steps and test each one before chaining them.

### How to approach it

1. List what the program trusts: input length, file names, the environment, the current directory, the time.
2. Look through the game's data directory for source code, helper files and anything readable that explains the setup.
3. For every library function the program calls, read its man page, especially the sections on return values, NOTES, BUGS and CAVEATS, and ask what the programmer assumed that the manual does not guarantee.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

### What to do next

- **Consolidate.** For each level, record the bug class, the tool that found it and the technique that worked.
- **Continue.** From the [games index](../../), Utumno is a natural next step.
- **Read about defences.** Stack canaries, non-executable memory, ASLR and RELRO each map to attacks you have practised.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../manpage6/">Level 6</a><a class="sg-index" href="../">Manpage overview</a><span></span></nav>

</section>

<!-- study-guide:end -->
