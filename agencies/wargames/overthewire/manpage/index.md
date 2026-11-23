---
title: Manpage
description: "Manpage teaches how to find bugs by reading manual pages: its levels break common misconceptions about Linux C programming."
excerpt: "Manpage teaches how to find bugs by reading manual pages: its levels break common misconceptions about Linux C programming."
permalink: /docs/wargames/manpage/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/manpage/index.md
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
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Manpage
=======

### Can you RTFM?

Manpage is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on manpage.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of manpage, copied from intruded.net:

    Summary:
    Difficulty:     x/10
    Levels:         7
    Platform:   Linux/x86

    Author:
    adc

    Special Thanks:

    Description:
    This game is about breaking some common linux c-programming misconceptions. A good
    tactic when beginning to audit code for the first time is to read the manpages for pitfalls and 
    unusual behavior. Many of these levels were inspired by the famous work of Ilja.

Manpage's levels are called **manpage0, manpage1, ... etc.** and can be accessed on **manpage.labs.overthewire.org** through SSH on port 2224.

To login to the first level use:

    Username: manpage0
    Password: manpage0

Data for the levels can be found in **/manpage/**.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free. It explains how to approach Manpage and what each stage asks of you, but upstream deliberately withholds level descriptions, so there are no level-specific claims here beyond what the index says.

### What Manpage teaches

Manpage is about breaking common Linux C-programming misconceptions. Its author's advice is that a good way to begin auditing code is to read the manual pages for pitfalls and unusual behaviour.

### Connecting

Manpage is reached with SSH at `manpage.labs.overthewire.org` on port 2224. Levels are accounts called `manpage0`, `manpage1` and so on, and the level data is in `/manpage/`. These games were rescued from the defunct intruded.net with thanks to adc, morla and reth.

### Why read the manual?

The author explains that a good tactic when beginning to audit code is to read the manual pages for pitfalls and unusual behaviour, and that many levels were inspired by "the famous work of Ilja". Typical C pitfalls to look up include:

- `strncpy` does not always NUL-terminate its result.
- `read` and `write` may transfer fewer bytes than requested.
- `fgets` keeps the trailing newline, and `atoi` cannot report errors.
- `snprintf` returns the length it *wanted* to write, not what it wrote.
- Mixing signed and unsigned integers in length checks.
- `access()` checks permissions at one moment, and the file may change before it is used.

These are examples of misconceptions to examine, not a list of what the levels contain.

### A reconnaissance checklist

1. `ls -l /manpage/` and look at the permissions. A setuid bit marks the program that is your route to the next user.
2. `file` and `strings` on the binary.
3. Run it normally, then with odd input.
4. `ltrace` and `strace` for library and system calls.
5. `gdb` or `objdump -d` for the logic.
6. Decide what kind of flaw you are looking at before choosing an attack.

### How the levels are numbered

The page for Level N is the account `manpageN`. Each level's password is typically stored in a file readable only by the next user, and your task is to get the program for level N to read or reveal it.

### Tools

`gdb`, `objdump`, `ltrace`, `strace`, `ghidra`, `gcc`, `nc`, `pwntools`, and a notes file for addresses, offsets and observations.

### Keep it ethical

Everything here is for the wargame servers. Do not attack other systems, and do not share passwords or complete solutions that would spoil the game for others.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="manpage0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
