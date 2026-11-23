---
title: "Manpage Level 5"
description: "Manpage Level 5 — an intentionally undocumented later level, with a method for investigating it."
excerpt: "Manpage Level 5 — an intentionally undocumented later level, with a method for investigating it."
permalink: /docs/wargames/manpage/manpage5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/manpage/manpage5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `manpage5`, find the password for `manpage6`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Manpage is about breaking common Linux C-programming misconceptions. Its author's advice is that a good way to begin auditing code is to read the manual pages for pitfalls and unusual behaviour.

### Where it fits

Manpage is given only as x/10 in its original description, so effectively unrated, and lives under `/manpage/` on the game server (SSH port 2224). This is page 6 of 8 in this mirror. Later levels tend to combine ideas from earlier ones, so reread your notes on previous levels for tools you can reuse.

### How to approach it

1. Try unusual input: nothing, far too much, special characters, and unexpected arguments or environment variables.
2. Start with `file` and `strings` on the level's program to learn what it is and what text it contains.
3. For every library function the program calls, read its man page, especially the sections on return values, NOTES, BUGS and CAVEATS, and ask what the programmer assumed that the manual does not guarantee.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../manpage4/">Level 4</a><a class="sg-index" href="../">Manpage overview</a><a class="sg-next" href="../manpage6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
