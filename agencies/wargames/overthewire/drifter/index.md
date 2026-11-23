---
title: Drifter
description: "Drifter is a 16-level advanced wargame in the style of Vortex, mixing remote services, heap bugs, format strings, reversing and ASLR bypass."
excerpt: "Drifter is a 16-level advanced wargame in the style of Vortex, mixing remote services, heap bugs, format strings, reversing and ASLR bypass."
permalink: /docs/wargames/drifter/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/index.md
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
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Drifter
=======

Drifter is a wargame along the lines of Vortex.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains what each Drifter level asks for, based on the level pages, without passwords or finished exploits.

### What Drifter teaches

The upstream description is one sentence: Drifter is a wargame along the lines of Vortex. Its levels use the same toolkit — network clients, stack and heap exploitation, format strings, reverse engineering and cryptanalysis — but on a different mix of targets, including remote daemons, C++ code, third-party libraries and ASLR-protected binaries.

### Connecting

Drifter is reached with SSH at `drifter.labs.overthewire.org` on port 2230. Level 0 is a network service that listens on port 1111. Source code for several levels is provided under `/drifter/` (for example `drifter0_src`, `drifter3_src` and `drifter14_src`).

### Prerequisites

Finish Bandit, Narnia and Behemoth, and ideally the early Vortex levels. The Drifter Level 0 page even suggests doing Vortex Level 0 first, to have a stable machine to work from if you are behind NAT.

### The skills ladder

| Levels | Theme | Core skills |
|--------|-------|-------------|
| 0 | Remote system-call proxy | RC4, raw syscalls, a custom client |
| 1–3 | Memory corruption | C++ vtables, stack overflow quirks, old heap allocators |
| 4–5 | Analysis and logic | reverse engineering, resource limits, game logic |
| 6–8 | Remote daemons | format strings, disassembly, custom shellcode |
| 9–10 | Privileges and practice | file formats, non-executable stacks |
| 11–12 | Randomisation and reversing | ASLR, RPC-style protocols |
| 13–15 | Open-ended | unexpected approaches, third-party library bugs, decompression |

### Tools

`gdb`, `objdump`, `ltrace`/`strace`, a disassembler (the Level 7 page mentions IDA Free), `gcc`, `pwntools`, Python and C for network clients.

### Habits that help

- Read the source where it is given before touching the binary.
- Script everything; remote exploits need many attempts.
- Keep a record of addresses and offsets, as they differ between levels and sometimes between runs.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="drifter0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
