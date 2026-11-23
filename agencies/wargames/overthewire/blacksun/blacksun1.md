---
title: "Blacksun Level 1"
description: "Blacksun Level 1 — a trivial stack overflow in a binary with ASLR but no PIE and no stack protector, so fixed program addresses can be used."
excerpt: "Blacksun Level 1 — a trivial stack overflow in a binary with ASLR but no PIE and no stack protector, so fixed program addresses can be used."
permalink: /docs/wargames/blacksun/blacksun1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/blacksun1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level1 is a trivial stack buffer overflow. Note that you'll probably find it easier to use the compiled version than compiling it from source.

### Binary information

| Stack smashing protection (SSP): 	      | Disabled	|
| Postition Independent Executable (PIE):     | Disabled	|
| Address space layout randomisation (ASLR):  | Enabled - No PIE|
| Non-executable pages: 		      | None / disabled	|
|--------------------------------------------:+:----------------|
| Location: 				      | /levels/level1  |

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the vulnerable program is `/levels/level1` on the Blacksun host.
</div>

### What this level teaches

How to reason about which parts of an address space are randomised and which are not.

### Key ideas

- **ASLR without PIE.** The stack and libraries move, but the main program's code and data stay at fixed addresses, so you can still reference them.
- **No stack protector.** There is no canary to detect an overwritten return address.
- **Use the compiled binary.** The page notes that it is easier to analyse the compiled version than to compile the source yourself.
- **Non-executable pages are off,** so classic shellcode is possible, but you must find a reliable way to reach it.

### How to approach it

1. Check the protections with the table on the page and with tools such as `checksec`.
2. Find the offset to the return address in `gdb`.
3. Choose a return target that is stable despite randomisation.

### Why it matters

Understanding what each mitigation does and does not randomise is the heart of exploit development.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../blacksun0/">Level 0</a><a class="sg-index" href="../">Blacksun overview</a><a class="sg-next" href="../blacksun2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
