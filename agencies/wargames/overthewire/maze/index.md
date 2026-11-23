---
title: Maze
description: "Maze is a harder binary-exploitation wargame rated 5/10 that needs exploitation, programming and reverse-engineering skills, with deliberately tricky levels."
excerpt: "Maze is a harder binary-exploitation wargame rated 5/10 that needs exploitation, programming and reverse-engineering skills, with deliberately tricky levels."
permalink: /docs/wargames/maze/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/maze/index.md
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
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Maze
====

### Can you find the way out?

Maze is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on maze.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of maze, copied from intruded.net:

    Summary:
    Difficulty:     5/10
    Levels:         9
    Platform:   Linux/x86

    Author:
    beng and capsyl

    Special Thanks:
    je for doing the primary beta-testing.
    kuba for beta-testing and ideas.
    psi for level9

    Description:
    You'll need knowledge of exploitation-techniques, programming (of course) and reverse-
    engineering. We've tried to make the levels tricky and some of them strange, so get ready
    to use gdb.

Maze's levels are called **maze0, maze1, ... etc.** and can be accessed on **maze.labs.overthewire.org** through SSH on port 2225.

To login to the first level use:

    Username: maze0
    Password: maze0

Data for the levels can be found in **/maze/**.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free. It explains how to approach Maze and what each stage asks of you, but upstream deliberately withholds level descriptions, so there are no level-specific claims here beyond what the index says.

### What Maze teaches

Maze is a harder binary-exploitation wargame. Its authors say it needs knowledge of exploitation techniques, programming and reverse engineering, and that the levels are deliberately tricky and sometimes strange.

### Connecting

Maze is reached with SSH at `maze.labs.overthewire.org` on port 2225. Levels are accounts called `maze0`, `maze1` and so on, and the level data is in `/maze/`. These games were rescued from the defunct intruded.net with thanks to adc, morla and reth.

### Prerequisites

Finish Narnia, Behemoth and ideally Utumno. The authors list the requirements as knowledge of exploitation techniques, programming (of course) and reverse engineering, and recommend getting ready to use `gdb`.

### A reconnaissance checklist

1. `ls -l /maze/` and look at the permissions. A setuid bit marks the program that is your route to the next user.
2. `file` and `strings` on the binary.
3. Run it normally, then with odd input.
4. `ltrace` and `strace` for library and system calls.
5. `gdb` or `objdump -d` for the logic.
6. Decide what kind of flaw you are looking at before choosing an attack.

### How the levels are numbered

The page for Level N is the account `mazeN`. Each level's password is typically stored in a file readable only by the next user, and your task is to get the program for level N to read or reveal it.

### Tools

`gdb`, `objdump`, `ltrace`, `strace`, `ghidra`, `gcc`, `nc`, `pwntools`, and a notes file for addresses, offsets and observations.

### Keep it ethical

Everything here is for the wargame servers. Do not attack other systems, and do not share passwords or complete solutions that would spoil the game for others.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="maze0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
