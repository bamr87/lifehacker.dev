---
title: "Blacksun"
description: "Blacksun is an advanced exploitation wargame (currently down) about attacking hardened hosts that use ASLR, non-executable memory and stack protection."
excerpt: "Blacksun is an advanced exploitation wargame (currently down) about attacking hardened hosts that use ASLR, non-executable memory and stack protection."
permalink: /docs/wargames/blacksun/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- blacksun
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- index
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.


The blacksun wargame is temporarily down because we have lost the backup (shame on us). We are currently collecting the levels from third parties to bring the game back.


### About

Blacksun is a PullThePlug / OverTheWire wargame that is meant to help people learn more advanced exploitation techniques against hardened hosts and environments. It is implemented by PaX patches, and the Hardened Gentoo project. **It is a work in process** If you have any questions you can contact [andrewg][] via email.

Blacksun is not an exploit novice's game / toolset, as it assumes a bunch of previous knowledge, such as programming, format string exploitation, heap exploitation, shellcoding, and out of the box thinking, amongst other things. However, PullThePlug / OverTheWire does have another wargame that's a lot easier, but still quite challenging available [here][].

**Also, it is not meant to discredit any of the work that has been done towards PaX (hi pipacs!), as it is quite awesome. Perhaps even it will lead to better defensive, and maybe better offensive techniques. And most likely greater understanding with the issues involved.**

### Aims

Blacksun is aimed towards demonstrating and helping people better understand:

-   Address space randomisation
-   Non executable memory and things that affect it
-   Stack smashing prevention
-   Information leaks
-   Code auditing and identifying code paths and vulnerable constructs
-   Being able to construct the exploitation environment
-   Binary auditing, and differencing
-   Access control list systems

### Reading material

A list of suggested reading material can be found [here][readingmaterial]

  [andrewg]: mailto:andrewg@felinemenace.org
  [here]: {{ '/docs/wargames/vortex/' | relative_url }}
  [readingmaterial]: https://overthewire.org/wargames/blacksun/reading_material.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains what the Blacksun material covers and how to study it. The game is currently offline, so these pages are best read as a curriculum rather than a live challenge.

### Status

The upstream page states that the Blacksun wargame is temporarily down because the backup was lost, and that the maintainers are collecting the levels from third parties to bring it back. Check the [upstream Blacksun page](https://overthewire.org/wargames/blacksun/) for news.

### What Blacksun teaches

Blacksun targets players who already know programming, format-string exploitation, heap exploitation and shellcoding. It is built on PaX patches and Hardened Gentoo, so the exploits you have practised on easier systems will not simply work. The stated aims are to understand:

- Address space layout randomisation (ASLR)
- Non-executable memory and what weakens it
- Stack-smashing prevention
- Information leaks
- Code auditing and identifying vulnerable code paths
- Building the exploitation environment
- Binary auditing and differencing
- Access-control list systems

### Prerequisites

Finish Narnia and Behemoth first, and be comfortable with `gdb`, C, assembly and writing shellcode. The Blacksun index itself points to Vortex as an easier alternative from the same community.

### The levels at a glance

| Level | Bug | Protections in place |
|-------|-----|----------------------|
| 0 | remote format string | SSP, PIE and ASLR on; non-executable pages off |
| 1 | stack buffer overflow | ASLR on but no PIE and no SSP |
| 2 | bugs in a POP3 client library | ASLR on, no SSP, no PIE |
| 3 | unknown, stripped binary | SSP and ASLR on, no PIE |
| 4 | introduced heap bug in Apache and PHP | SSP, PIE and ASLR on |

Each level page includes a table of exactly which protections are enabled, which tells you what you can and cannot rely on.

### Tools and habits

`gdb`, `objdump`, `ghidra`, `pwntools`, and a note-taking habit. For long-running remote levels, write your exploit as a script, because you will need many attempts to beat randomisation.

### Reading material

See the [reading list](reading_material/) for papers on format strings, heap exploitation, frame-pointer overwrites, ASLR and PaX, Execshield, stack protection and hardware protections.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="blacksun0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
