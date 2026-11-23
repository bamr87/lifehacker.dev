---
title: Leviathan
description: "Leviathan is a beginner reverse-engineering wargame of 8 levels where you study small setuid programs to learn how they decide to give up a password."
excerpt: "Leviathan is a beginner reverse-engineering wargame of 8 levels where you study small setuid programs to learn how they decide to give up a password."
permalink: /docs/wargames/leviathan/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Leviathan
=========

### Dare you face the lord of the oceans?

Leviathan is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on leviathan.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of leviathan, copied from intruded.net:

    Summary:
    Difficulty:     1/10
    Levels:         8
    Platform:   Linux/x86

    Author:
    Anders Tonfeldt

    Special Thanks:
    We would like to thank AstroMonk for coming up with a replacement idea for the last level,
    deadfood for finding a leveljump and Coi for finding a non-planned vulnerability.

    Description:
    This wargame doesn't require any knowledge about programming - just a bit of common
    sense and some knowledge about basic *nix commands. We had no idea that it'd be this
    hard to make an interesting wargame that wouldn't require programming abilities from 
    the players. Hopefully we made an interesting challenge for the new ones.

Leviathan's levels are called **leviathan0, leviathan1, ... etc.** and can be accessed on **leviathan.labs.overthewire.org** through SSH on port 2223.

To login to the first level use:

    Username: leviathan0
    Password: leviathan0

Data for the levels can be found in **the homedirectories**. You can look at **/etc/leviathan_pass** for the various level passwords.

Tools you may find useful to solve this wargame
-----------------------------------------------

strings, hexdump, objdump, ghidra

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains the skills Leviathan builds and how to approach unknown programs, but it never gives passwords or finished solutions.

### What Leviathan teaches

Leviathan is the gentlest introduction to analysing a program you did not write. The original authors say it requires no programming knowledge, only common sense and a feel for basic Unix commands. You log in as `leviathan0` (password `leviathan0`), explore the home directory, and each level hands you a small program or hidden clue to understand.

### How the levels are numbered

The page for Level N is the account you are logged in as. You are `leviathanN` and you are looking for the password for `leviathanN+1`. Passwords for all levels are stored in `/etc/leviathan_pass/`, each readable only by the matching user, so the real task is always getting a program to read the right file on your behalf.

### The skills ladder

| Levels | Theme | Core skills |
|--------|-------|-------------|
| 0–1 | Looking and listening | hidden files, `ls -la`, tracing library calls with `ltrace` |
| 2–3 | Reading what a program does | how programs open files, string comparisons, filenames |
| 4–5 | Data in disguise and links | number bases and encodings, symbolic links |
| 6 | Automation | brute-forcing a small secret with a loop |
| 7 | The end | consolidate |

### Tools worth learning

- `ls -la` — list everything, including hidden files and the permissions that matter.
- `file`, `strings`, `hexdump` — first look at an unknown file.
- `ltrace` and `strace` — run a program and print the library calls or system calls it makes. These two often answer a level in seconds.
- `objdump` and **Ghidra** — disassembler and decompiler for when tracing is not enough.
- `ln -s` — create symbolic links.

### Tips

- Run a program with no arguments and then with odd arguments; its error messages are free documentation.
- Work in a directory under `/tmp` made with `mktemp -d` when you need to create files.
- Write down what each program *assumes* about its input; every level breaks one such assumption.

### Where this fits

Leviathan is rated 1 out of 10 by its authors. The suggested path is Bandit, then one of Natas, Krypton or Leviathan, then Narnia for binary exploitation.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="leviathan0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
