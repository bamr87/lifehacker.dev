---
title: "Manpage Level 0"
description: "Manpage Level 0 — an intentionally undocumented first level, with a method for investigating it."
excerpt: "Manpage Level 0 — an intentionally undocumented first level, with a method for investigating it."
permalink: /docs/wargames/manpage/manpage0/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/manpage/manpage0.md
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
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `manpage0`, find the password for `manpage1`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Manpage is about breaking common Linux C-programming misconceptions. Its author's advice is that a good way to begin auditing code is to read the manual pages for pitfalls and unusual behaviour.

### Where it fits

Manpage is given only as x/10 in its original description, so effectively unrated, and lives under `/manpage/` on the game server (SSH port 2224). This is page 1 of 8 in this mirror. Treat the first level as orientation: learn the account layout, the data directory and the tools available before looking for a bug.

### How to approach it

1. Start with `file` and `strings` on the level's program to learn what it is and what text it contains.
2. Check permissions with `ls -l`: a setuid or setgid bit tells you whose privileges the program runs with.
3. For every library function the program calls, read its man page, especially the sections on return values, NOTES, BUGS and CAVEATS, and ask what the programmer assumed that the manual does not guarantee.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Manpage overview</a><a class="sg-next" href="../manpage1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
