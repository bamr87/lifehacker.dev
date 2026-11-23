---
title: "Blacksun Level 3"
description: "Blacksun Level 3 — analyse a stripped binary with little documentation, work out what it expects, and exploit it, with some brute force."
excerpt: "Blacksun Level 3 — analyse a stripped binary with little documentation, work out what it expects, and exploit it, with some brute force."
permalink: /docs/wargames/blacksun/blacksun3/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/blacksun3.md
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
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level3 is a blast from the past, with not much details and a sstriped binary!

Experiment around / partially disassemble level3, work out what it wants, and how to exploit it. Some bruteforcing may be required ;)

### Binary information

| Stack smashing protection (SSP):            | Enabled         |
| Postition Independent Executable (PIE):     | Disabled        |
| Address space layout randomisation (ASLR):  | Enabled 	|
| Non-executable pages:                       | None / disabled |
|--------------------------------------------:+:----------------|
| Location:                                   | /levels/level3  |

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the target is `/levels/level3`; it is a stripped binary with stack protection and ASLR on and PIE off.
</div>

### What this level teaches

Reverse engineering with no symbols and no source.

### Key ideas

- **Stripped binaries.** Function names are gone, so you identify functions by behaviour and by the library calls they make.
- **Partial disassembly.** The page encourages experimenting and disassembling only the interesting parts.
- **Stack protector.** With SSP enabled, overwriting the return address crudely will abort the program, so you need a way around or an information leak.
- **Brute force.** If a protection value has few possibilities per attempt, repeated attempts can defeat it.

### How to approach it

1. Run the program, observe its behaviour and input format, and trace its system calls.
2. Disassemble the input-handling path in `objdump` or Ghidra.
3. Identify the weakness and decide whether a leak or brute force is the practical bypass.

### Why it matters

Most real targets have no source. Learning to find the bug from the binary is a core skill.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../blacksun2/">Level 2</a><a class="sg-index" href="../">Blacksun overview</a><a class="sg-next" href="../blacksun4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
