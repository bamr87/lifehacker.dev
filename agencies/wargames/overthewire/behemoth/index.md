---
title: Behemoth
description: "Behemoth is an intermediate wargame of 9 levels on buffer overflows, format strings and race conditions in binaries given without source."
excerpt: "Behemoth is an intermediate wargame of 9 levels on buffer overflows, format strings and race conditions in binaries given without source."
permalink: /docs/wargames/behemoth/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- behemoth
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/behemoth/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- behemoth
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Behemoth
========

### Don't let behemoth get the better of you.

Behemoth is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on behemoth.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of behemoth, copied from intruded.net:

    Summary:
    Difficulty:     3/10
    Levels:         9
    Platform:   Linux/x86

    Author:
    Anders Tonfeldt

    Special Thanks:

    Description:
    This wargame deals with a lot of regular vulnerabilities found commonly 'out 
    in the wild'. While the game makes no attempts at emulating a real environment
    it will teach you how to exploit several of the most common coding mistakes 
    including buffer overflows, race conditions and privilege escalation.

Behemoth's levels are called **behemoth0, behemoth1, ... etc.** and can be accessed on **behemoth.labs.overthewire.org** through SSH on port 2221.

To login to the first level use:

    Username: behemoth0
    Password: behemoth0

Data for the levels can be found in **/behemoth/**.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains what Behemoth expects of you and how to work, but never gives passwords or finished exploits.

### What Behemoth teaches

The original description from intruded.net says the game deals with regular vulnerabilities commonly found "out in the wild" and, while it makes no attempt to emulate a real environment, teaches several of the most common coding mistakes including buffer overflows, race conditions and privilege escalation. The authors rated it 3 out of 10, on Linux/x86, and Utumno's authors call it a little easier than their own game.

### Connecting

Behemoth is rescued from the defunct intruded.net, thanks to adc, morla and reth. Connect with SSH to `behemoth.labs.overthewire.org` on port 2221. The first account is `behemoth0` with the password `behemoth0`. Data for the levels is in `/behemoth/`, and each level's password is in `/etc/behemoth_pass/`, readable only by that level's user.

### How the levels are numbered

The page for Level N is the account you are logged in as. You are `behemothN` and you are looking for the password for `behemothN+1`. The upstream pages deliberately say nothing more.

### How it differs from Narnia

Narnia hands you the C source. Behemoth gives you the compiled program, so you must learn what it does from tracing and disassembly before you can exploit it.

### A reconnaissance checklist

1. `ls -l /behemoth/` and look at the permissions. A setuid bit marks the program as your route to the next user.
2. `file` and `strings` on the binary.
3. Run it normally, then with odd input.
4. `ltrace` and `strace` for library and system calls.
5. `gdb` or `objdump -d` for the logic.
6. Decide what kind of bug you are looking at before choosing an exploit.

### Tools

`gdb` (optionally with a helper like `gef` or `pwndbg`), `objdump`, `ltrace`, `strace`, `ghidra`, `gcc`, `nc`, `pwntools`, and a notes file.

### Where this fits

The recommended order is Bandit, one of Natas, Krypton or Leviathan, Narnia, then Behemoth, then Utumno and Maze.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="behemoth0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
