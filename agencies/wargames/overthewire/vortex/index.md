---
title: Vortex
description: "Vortex is an advanced 27-level wargame covering network programming, binary exploitation, heap bugs, weak randomness, cryptanalysis and reverse engineering."
excerpt: "Vortex is an advanced 27-level wargame covering network programming, binary exploitation, heap bugs, weak randomness, cryptanalysis and reverse engineering."
permalink: /docs/wargames/vortex/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Vortex
======

The Vortex wargame is currently composed of 27 levels. Most files you need are in /vortex/. Special thanks to the many people who have helped setup and maintain this wargame.

Many thanks to those who have made sure all levels can be played

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains the skills each Vortex level asks for, using only what the level pages say, and never lists passwords or solutions.

### What Vortex teaches

Vortex is a long, varied course in low-level security. It begins with a small network programming task, passes through stack overflows, format strings, heap corruption and non-executable stacks, then turns to reverse engineering, weak cryptography and predictable random numbers. Many of its levels run on an old 32-bit x86 machine, so values are little-endian and addresses are 32 bits. The index notes that most files you need are in `/vortex/`.

### Status of the game

The maintainers state the game is composed of 27 levels (0 to 26) and is no longer being expanded. Level 25 is described as lost (kept for history) and Level 26 asks players to create their own level, which is no longer active.

### Prerequisites

Finish Bandit, then Narnia and Behemoth. You should be able to read C, use `gdb`, write simple networked programs and understand the stack. Beej's guides to C and to network programming, which Level 0 links, are the recommended starting point.

### How the levels are numbered

The page for Level N describes the challenge that gives you credentials for the next Vortex account. Some levels are solved over the network and some by logging in to `vortex.labs.overthewire.org`, as individual pages note.

### The skills ladder

| Levels | Theme | Core skills |
|--------|-------|-------------|
| 0 | Network programming | sockets, byte order, 32-bit arithmetic |
| 1–4 | Classic memory bugs | overflows, relocation sections, format strings, archive formats |
| 5–8 | Brute force and reversing | MD5 search, binary exploitation, CRC, disassembly |
| 9–13 | Black boxes and mitigations | randomness, heap corruption, non-executable stacks, small shellcode |
| 14–16 | Cryptography in practice | weak protocols, weak file encryption, partial hash search |
| 17–19 | Randomness and keygens | working backwards, `urandom` seeds, key generation |
| 20–24 | Reverse engineering and research | integer bugs, reversing, object files, PRNG internals |
| 25–26 | Historical | lost level and community contribution |

### Tools

`gdb`, `objdump`, `ltrace`/`strace`, `gcc`, Python or C for networking and brute force, a hex editor, and a disassembler such as Ghidra or IDA Free.

### Habits that help

- Write a script for every exploit; you will rerun it often.
- Keep notes on memory layouts and addresses.
- Read the reading list at the bottom of each page before you start; many levels are direct applications of those papers.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="vortex0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
