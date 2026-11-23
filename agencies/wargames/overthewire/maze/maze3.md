---
title: "Maze Level 3"
description: "Maze Level 3 — an intentionally undocumented mid-game level, with a method for investigating it."
excerpt: "Maze Level 3 — an intentionally undocumented mid-game level, with a method for investigating it."
permalink: /docs/wargames/maze/maze3/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- maze
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/maze/maze3.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- maze
author: bamr87
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `maze3`, find the password for `maze4`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Maze is a harder binary-exploitation wargame. Its authors say it needs knowledge of exploitation techniques, programming and reverse engineering, and that the levels are deliberately tricky and sometimes strange.

### Where it fits

Maze is rated 5/10 by its original authors, and lives under `/maze/` on the game server (SSH port 2225). This is page 4 of 10 in this mirror. Mid-game levels in wargames like this often add constraints that break the textbook technique, such as filtered bytes or a cleared environment, so be ready to adapt.

### How to approach it

1. Check permissions with `ls -l`: a setuid or setgid bit tells you whose privileges the program runs with.
2. Open the program in `gdb`, break at `main`, and step through to see exactly how your input is used.
3. The authors' advice is to get ready to use `gdb`; step through the program rather than guessing.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../maze2/">Level 2</a><a class="sg-index" href="../">Maze overview</a><a class="sg-next" href="../maze4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
