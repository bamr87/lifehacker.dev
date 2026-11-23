---
title: "Drifter Level 5"
description: "Drifter Level 5 — a series of logic and mathematics games, one of which is always solvable and can be understood by reverse engineering."
excerpt: "Drifter Level 5 — a series of logic and mathematics games, one of which is always solvable and can be understood by reverse engineering."
permalink: /docs/wargames/drifter/drifter5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level 5 is a series of relatively simple logic/math games.

The game 3 is always solvable - if you are stuck on it you may wish to reverse engineer the applicable part of the binary ;) Granted, the coding for that was horrible, but it'd give you a way to solve it.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 5 of 0–15, in the analysis and logic stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Solving puzzle-style challenges by reading the code behind them.

### Key ideas

- **Several mini-games.** Each tests logic or arithmetic.
- **Game 3 is always solvable.** If you are stuck on it, the page suggests reverse engineering the relevant part of the binary; it also warns that the code is badly written, which makes reading it a good exercise in its own right.
- **Programmatic solutions.** Write a solver rather than playing by hand.

### How to approach it

1. Play each game manually to understand its rules.
2. Where it helps, read the corresponding binary function.
3. Write a script to solve them quickly.

### Why it matters

Reading poor-quality code is routine in security work.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter4/">Level 4</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
