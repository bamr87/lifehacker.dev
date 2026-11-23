---
title: "Blacksun Level 0"
description: "Blacksun Level 0 — exploit a remote format-string bug in a binary with ASLR, PIE and stack protection by using direct parameter access to study the stack."
excerpt: "Blacksun Level 0 — exploit a remote format-string bug in a binary with ASLR, PIE and stack protection by using direct parameter access to study the stack."
permalink: /docs/wargames/blacksun/blacksun0/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/blacksun0.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- blacksun
author: bamr87
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level0 is a remote format string intended to get you started with blacksun. It is a remote format string bug with you being able to see the reply, with address space randomisation enabled. You'll need to use the direct parameter access method to analyse the stack and to manipulate it.

Once getting access to a shell, read /etc/motd for more information

### Binary information

| Stack smashing protection (SSP):            | Enabled         				|
| Postition Independent Executable (PIE):     | Enabled         				|
| Address space layout randomisation (ASLR):  | Enabled         				|
| Non-executable pages:                       | None / disabled                             	|
|--------------------------------------------:+:------------------------------------------------|
| Location:                                   | Connect to blacksun.overthewire.org on port 79 	|

Alternatively, there is a debug version on port 78 if you need help understanding what you're seeing

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** you attack a network service (port 79, with a debug version on port 78) to get a shell, then read `/etc/motd` for more information.
</div>

### What this level teaches

How to exploit a format-string vulnerability remotely when the layout of memory is randomised.

### Key ideas

- **You can see the reply.** That is what makes a leak possible: format specifiers print stack values back to you.
- **Direct parameter access.** The `%N$x` syntax reads the Nth argument directly, so you can scan the stack without writing hundreds of specifiers.
- **Defeating ASLR with a leak.** If you can read a pointer from the stack, you can compute where other things are for that particular run.
- **Protections table.** The page lists SSP, PIE and ASLR as on, and non-executable pages as off, so injected shellcode on the stack is still allowed.
- **Debug version.** Port 78 serves a version that explains what you are seeing.

### How to approach it

1. Use the debug service to understand the stack layout, then repeat on the real one.
2. Leak the values you need, compute addresses, and design the write.
3. Script the exploit so you can rerun it against a fresh address space.

### Why it matters

Info leaks plus a write primitive are the building blocks of nearly every modern exploit chain.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Blacksun overview</a><a class="sg-next" href="../blacksun1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
