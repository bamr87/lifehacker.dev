---
title: Narnia
description: "Narnia is the first binary-exploitation wargame — 10 levels where you read C source code and abuse common memory bugs like overflows and format strings."
excerpt: "Narnia is the first binary-exploitation wargame — 10 levels where you read C source code and abuse common memory bugs like overflows and format strings."
permalink: /docs/wargames/narnia/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- narnia
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- narnia
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Narnia
======

### We all have to start somewhere.

Narnia is a wargame that has been rescued from the demise of **intruded.net**, previously hosted on narnia.intruded.net. **Big thanks to adc, morla and reth** for their help in resurrecting this game!

What follows below is the original description of narnia, copied from intruded.net:

    Summary:
    Difficulty:     2/10
    Levels:         10
    Platform:   Linux/x86

    Author:
    nite

    Special Thanks:
    lx_jakal for pointing out a bug that made a level easier =)

    Description:
    This wargame is for the ones that want to learn basic exploitation. You can see the most
    common bugs in this game and we've tried to make them easy to exploit. You'll get the
    source code of each level to make it easier for you to spot the vuln and abuse it. The
    difficulty of the game is somewhere between Leviathan and Behemoth, but some of the
    levels could be quite tricky.

Narnia's levels are called **narnia0, narnia1, ... etc.** and can be accessed on **narnia.labs.overthewire.org** through SSH on port 2226.

To login to the first level use:

    Username: narnia0
    Password: narnia0

Data for the levels can be found in **/narnia/**.

Tools you may find useful to solve this wargame
-----------------------------------------------

objdump, ghidra, pwntools, gcc, gdb

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains what Narnia teaches and how to work, but it never gives finished exploits, payloads or passwords.

### What Narnia teaches

Narnia introduces *memory corruption*: bugs where a program writes outside the space it set aside, letting an attacker change what it does next. The authors rate it 2 out of 10 and place it between Leviathan and Behemoth. You are given the C source code of every level, so the question is never "what does it do?" but "what can I make it do?".

### How the levels are numbered

The page for Level N is the account you are logged in as. You are `narniaN` and your aim is the password for `narniaN+1`. Each level's vulnerable program and source live in `/narnia/` (for example `/narnia/narnia0` and `/narnia/narnia0.c`), and the program is setuid to the next user so that exploiting it lets you read that user's password. The upstream pages deliberately contain no hints.

### Concepts you will meet

- **The stack.** Where a function's local variables and its saved return address are kept. Writing past the end of a local buffer can overwrite things that sit next to it.
- **Endianness.** On x86, multi-byte numbers are stored least-significant byte first, so values you write into memory must be reversed.
- **Shellcode.** Small machine-code programs, usually starting a shell, injected into memory and then run.
- **Environment variables and arguments.** Handy places to put data into a program's memory.
- **Format strings.** Passing user data as the first argument of `printf` lets an attacker read and write memory.
- **Return-to-library.** Calling existing library functions instead of injecting new code.

### Tools

`gdb` (with a helper such as `pwndbg` or `gef` if you like), `objdump`, `ghidra`, `gcc`, `pwntools` for scripting exploits, and Python or Perl one-liners for building payloads. The Narnia index suggests exactly these.

### A working method

1. Read the source and ask which function copies or prints user data without checking its size.
2. Run the program normally and with oversized input to confirm a crash.
3. Use `gdb` to find exactly where your input lands and what you overwrite.
4. Build the smallest payload that proves control, then extend it.
5. Keep notes on stack layouts you discovered; they differ between levels.

### Safety and ethics

Exploit development against your own lab machines and wargames is legal and educational; do not run these techniques against systems you have no permission to test.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="narnia0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
