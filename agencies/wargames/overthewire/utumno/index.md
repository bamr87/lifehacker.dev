---
title: Utumno
description: "Utumno is a binary-exploitation wargame rated 4/10 by its authors — slightly harder than Behemoth — with undocumented levels you analyse yourself."
excerpt: "Utumno is a binary-exploitation wargame rated 4/10 by its authors — slightly harder than Behemoth — with undocumented levels you analyse yourself."
permalink: /docs/wargames/utumno/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- utumno
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/utumno/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- utumno
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Utumno
======

### Are you adequate?

Utumno is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on utumno.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of utumno, copied from intruded.net:

    Summary:
    Difficulty:     4/10
    Levels:         10
    Platform:   Linux/x86

    Author:
    Kuba and psi

    Special Thanks:

    Description:
    This is a regular wargame composed of 10 different levels. It's slightly harder than the
    previous wargames in the same genre. Actually, it's a lot harder than Leviathan and a bit
    harder than Behemoth so if you haven't beaten those two you will probably want to do that
    first.

Utumno's levels are called **utumno0, utumno1, ... etc.** and can be accessed on **utumno.labs.overthewire.org** through SSH on port 2227.

To login to the first level use:

    Username: utumno0
    Password: utumno0

Data for the levels can be found in **/utumno/**.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free. It explains how to approach Utumno and what each stage asks of you, but upstream deliberately withholds level descriptions, so there are no level-specific claims here beyond what the index says.

### What Utumno teaches

Utumno is a regular binary-exploitation wargame rescued from intruded.net. Its authors call it slightly harder than Behemoth and a lot harder than Leviathan.

### Connecting

Utumno is reached with SSH at `utumno.labs.overthewire.org` on port 2227. Levels are accounts called `utumno0`, `utumno1` and so on, and the level data is in `/utumno/`. These games were rescued from the defunct intruded.net with thanks to adc, morla and reth.

### Prerequisites

Finish Narnia and Behemoth first. The authors state that Utumno is a lot harder than Leviathan and a bit harder than Behemoth, so if you have not beaten those two you will probably want to do that before starting.

### A reconnaissance checklist

1. `ls -l /utumno/` and look at the permissions. A setuid bit marks the program that is your route to the next user.
2. `file` and `strings` on the binary.
3. Run it normally, then with odd input.
4. `ltrace` and `strace` for library and system calls.
5. `gdb` or `objdump -d` for the logic.
6. Decide what kind of flaw you are looking at before choosing an attack.

### How the levels are numbered

The page for Level N is the account `utumnoN`. Each level's password is typically stored in a file readable only by the next user, and your task is to get the program for level N to read or reveal it.

### Tools

`gdb`, `objdump`, `ltrace`, `strace`, `ghidra`, `gcc`, `nc`, `pwntools`, and a notes file for addresses, offsets and observations.

### Keep it ethical

Everything here is for the wargame servers. Do not attack other systems, and do not share passwords or complete solutions that would spoil the game for others.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="utumno0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
