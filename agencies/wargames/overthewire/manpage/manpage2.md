---
title: "Manpage Level 2"
description: "Manpage Level 2 — an intentionally undocumented mid-game level, with a method for investigating it."
excerpt: "Manpage Level 2 — an intentionally undocumented mid-game level, with a method for investigating it."
permalink: /docs/wargames/manpage/manpage2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/manpage/manpage2.md
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
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `manpage2`, find the password for `manpage3`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Manpage is about breaking common Linux C-programming misconceptions. Its author's advice is that a good way to begin auditing code is to read the manual pages for pitfalls and unusual behaviour.

### Where it fits

Manpage is given only as x/10 in its original description, so effectively unrated, and lives under `/manpage/` on the game server (SSH port 2224). This is page 3 of 8 in this mirror. Mid-game levels in wargames like this often add constraints that break the textbook technique, such as filtered bytes or a cleared environment, so be ready to adapt.

### How to approach it

1. Look through the game's data directory for source code, helper files and anything readable that explains the setup.
2. Try unusual input: nothing, far too much, special characters, and unexpected arguments or environment variables.
3. For every library function the program calls, read its man page, especially the sections on return values, NOTES, BUGS and CAVEATS, and ask what the programmer assumed that the manual does not guarantee.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../manpage1/">Level 1</a><a class="sg-index" href="../">Manpage overview</a><a class="sg-next" href="../manpage3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
