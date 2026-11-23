---
title: FormulaOne
description: "FormulaOne is a wargame rescued from intruded.net, played over SSH on port 2232, whose first task is to work out where its first level's source lives."
excerpt: "FormulaOne is a wargame rescued from intruded.net, played over SSH on port 2232, whose first task is to work out where its first level's source lives."
permalink: /docs/wargames/formulaone/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- formulaone
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/formulaone/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- formulaone
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

FormulaOne
====

FormulaOne is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on formulaone.intruded.net.


FormulaOne's levels are called **formulaone0, formulaone1, ... etc.** and can be accessed on **formulaone.labs.overthewire.org** through SSH on port 2232.

Data for the levels can be found in **/formulaone/**.

*The source code for the first level can be accessed by logging in to a wargame hosted on the same server. Your first task is figuring out which wargame that is.*

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free. It explains how to approach FormulaOne and what each stage asks of you, but upstream deliberately withholds level descriptions, so there are no level-specific claims here beyond what the index says.

### What FormulaOne teaches

FormulaOne is another wargame rescued from intruded.net. Its index gives very little away beyond where to connect.

### Connecting

FormulaOne is reached with SSH at `formulaone.labs.overthewire.org` on port 2232. Levels are accounts called `formulaone0`, `formulaone1` and so on, and the level data is in `/formulaone/`. These games were rescued from the defunct intruded.net with thanks to adc, morla and reth.

### Prerequisites

The index gives no difficulty rating. Treat it as an advanced game and finish Bandit, Leviathan and Narnia first.

### The first puzzle

The index says: the source code for the first level can be accessed by logging in to a wargame hosted on the same server, and your first task is figuring out which wargame that is. Think about which accounts and directories you can already reach.

### A reconnaissance checklist

1. `ls -l /formulaone/` and look at the permissions. A setuid bit marks the program that is your route to the next user.
2. `file` and `strings` on the binary.
3. Run it normally, then with odd input.
4. `ltrace` and `strace` for library and system calls.
5. `gdb` or `objdump -d` for the logic.
6. Decide what kind of flaw you are looking at before choosing an attack.

### How the levels are numbered

The page for Level N is the account `formulaoneN`. Each level's password is typically stored in a file readable only by the next user, and your task is to get the program for level N to read or reveal it.

### Tools

`gdb`, `objdump`, `ltrace`, `strace`, `ghidra`, `gcc`, `nc`, `pwntools`, and a notes file for addresses, offsets and observations.

### Keep it ethical

Everything here is for the wargame servers. Do not attack other systems, and do not share passwords or complete solutions that would spoil the game for others.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="formulaone0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
