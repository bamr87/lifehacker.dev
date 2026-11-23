---
title: "Semtex Level 0"
description: "Semtex Level 0 — receive a stream from a network port, discard every second byte, and run the executable that reveals the password."
excerpt: "Semtex Level 0 — receive a stream from a network port, discard every second byte, and run the executable that reveals the password."
permalink: /docs/wargames/semtex/semtex0/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- semtex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex0.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- semtex
author: bamr87
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Get a shell
-----------
semtex.labs.overthewire.org

| x86/elf:    | Connect to port 24000 |
| amd64/elf:  | Connect to port 24001 |
| ppc/mach-O: | Connect to port 24002 |


Receive data until the port is closed.

Every second byte you receive is trash, ignore it. The other bytes are an executable that shows you the password.

Then login to [semtex1@semtex.labs.overthewire.org][] on port 2229

**Thanks to mrx for the amd64 and ppc binaries!**

Reading Material
----------------
- [Beej's guide to network programming][]

[semtex1@semtex.labs.overthewire.org]: ssh://semtex1@semtex.labs.overthewire.org:2229
[Beej's guide to network programming]: http://beej.us/guide/bgnet/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** this level gives you the login for `semtex1`, used on port 2229.
</div>

### What this level teaches

Raw network reading and handling unusual file formats.

### Key ideas

- **Choose your platform.** The page lists three ports for three platforms: x86 ELF, amd64 ELF and PowerPC Mach-O. Pick the one you can run.
- **Read until the port closes,** then process the data.
- **Cleaning the stream.** Every second byte is garbage to ignore; the others form an executable.
- **Run it.** The program shows the password. Check its type with `file` first.
- **Reading.** Beej's guide to network programming is linked.

### How to approach it

1. Write a small client that connects, reads everything and saves it.
2. Remove the unwanted bytes with a script.
3. Mark the result executable and run it in a safe environment.

### Why it matters

Receiving untrusted executables is risky; analyse them in a virtual machine.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
