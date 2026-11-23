---
title: "Maze Level 2"
description: "Maze Level 2 — an intentionally undocumented early level, with a method for investigating it."
excerpt: "Maze Level 2 — an intentionally undocumented early level, with a method for investigating it."
permalink: /docs/wargames/maze/maze2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/maze/maze2.md
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
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `maze2`, find the password for `maze3`.
</div>

### What to expect

Upstream states "There is no information for this level, intentionally." That is part of the game: you discover what the level does by investigating it. Maze is a harder binary-exploitation wargame. Its authors say it needs knowledge of exploitation techniques, programming and reverse engineering, and that the levels are deliberately tricky and sometimes strange.

### Where it fits

Maze is rated 5/10 by its original authors, and lives under `/maze/` on the game server (SSH port 2225). This is page 3 of 10 in this mirror. Early levels in wargames like this often hinge on a single idea. State your hypothesis in one sentence before you write any exploit.

### How to approach it

1. Look through the game's data directory for source code, helper files and anything readable that explains the setup.
2. Try unusual input: nothing, far too much, special characters, and unexpected arguments or environment variables.
3. The authors' advice is to get ready to use `gdb`; step through the program rather than guessing.
4. Write down the one thing the program assumes about its input, then test what happens when that assumption is false.

### Why it matters

Each level is a miniature version of a real bug class. Working it out yourself without hints builds the investigative habits that no walkthrough can give you.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../maze1/">Level 1</a><a class="sg-index" href="../">Maze overview</a><a class="sg-next" href="../maze3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
