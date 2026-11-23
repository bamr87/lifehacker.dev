---
title: "Drifter Level 3"
description: "Drifter Level 3 — a remote heap corruption bug in a program linked against an old malloc implementation, with source supplied."
excerpt: "Drifter Level 3 — a remote heap corruption bug in a program linked against an old malloc implementation, with source supplied."
permalink: /docs/wargames/drifter/drifter3/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter3.md
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
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level 3 is a remote heap corruption issue. Source code can be found in /drifter/drifter3_src/. It is linked against an ancient malloc implementation so it should be easily exploitable :)

[Once upon a free()...][] - suitable reading material, amongst others.

  [Once upon a free()...]: http://phrack.org/archives/issues/57/9.txt

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 3 of 0–15, in the memory corruption stage of the game. The page does not say which account you start as, so check with `id` after connecting. The source is in `/drifter/drifter3_src/`.
</div>

### What this level teaches

Classic heap-metadata attacks against an allocator without modern checks.

### Key ideas

- **Ancient malloc.** The program uses an old allocator that does not validate its internal metadata, which the page says should make it easily exploitable.
- **Unlink-style attacks.** Corrupting a chunk's links so that a later free writes where you choose.
- **Remote.** You deliver the corruption over the network, so build a reliable client.
- **Reading.** "Once upon a free()..." is the suggested paper.

### How to approach it

1. Read the allocator behaviour and the program's use of it.
2. Find the overflow and what chunk it reaches.
3. Turn the corrupted metadata into a controlled write, then into code execution.

### Why it matters

Modern allocators add many checks because of exactly this class of attack.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter2/">Level 2</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
