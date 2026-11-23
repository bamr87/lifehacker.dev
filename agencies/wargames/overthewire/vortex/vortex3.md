---
title: "Vortex Level 3"
description: "Vortex Level 3 — a stack overflow with a twist, involving shellcode that must call setuid and the limits of overwriting constructor and destructor tables."
excerpt: "Vortex Level 3 — a stack overflow with a twist, involving shellcode that must call setuid and the limits of overwriting constructor and destructor tables."
permalink: /docs/wargames/vortex/vortex3/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex3.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

A Stack Overflow with a Difference
----------------------------------
This level is pretty straight forward. Just sit down and understand what the code is doing. Your shellcode will require a setuid(LEVEL4\_UID) since bash drops effective privileges. You could alternatively write a quick setuid(geteuid()) wrapper around bash.

**NOTE:** ctors/dtors might no longer be writable, although this level is compiled with *-Wl,-z,norelro*. Lookup some information about this e.g. [here][]

Reading Material
----------------
- [Smashing the Stack for Fun and Profit][]
- [Bypassing StackGuard and StackShield][]



[here]: http://unix.stackexchange.com/questions/8062/dtors-looks-writable-but-attempts-to-write-segfault
[Smashing the Stack for Fun and Profit]: http://phrack.org/issues/49/14.html#article
[Bypassing StackGuard and StackShield]: http://www.phrack.org/issues.html?issue=56&id=5#article

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex3`, obtain access to `vortex4`.
</div>

### What this level teaches

Writing shellcode that survives dropped privileges, and understanding binary hardening flags.

### Key ideas

- **Bash drops privilege.** The page notes that bash drops effective privileges, so your shellcode needs to call `setuid` itself, or you can use a tiny wrapper that does `setuid(geteuid())`.
- **ctors and dtors.** Old writable tables of constructors and destructors were classic overwrite targets.
- **Relocation hardening.** The level is compiled without full relocation read-only (`norelro`), yet the page notes the tables might no longer be writable; research why.
- **Reading.** "Smashing the Stack" and "Bypassing StackGuard and StackShield" are linked.

### How to approach it

1. Read the code until you can say what it does line by line.
2. Decide which overwrite target will work on this system, and verify it in `gdb`.
3. Write shellcode that sets the right user ID before starting a shell.

### Why it matters

Privilege handling in shells and the evolution of mitigations like RELRO explain why old exploit recipes stop working.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex2/">Level 2</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
