---
title: "Drifter Level 1"
description: "Drifter Level 1 — a file-parsing heap corruption bug in C++ code, where overwriting an object's virtual-function pointer redirects execution."
excerpt: "Drifter Level 1 — a file-parsing heap corruption bug in C++ code, where overwriting an object's virtual-function pointer redirects execution."
permalink: /docs/wargames/drifter/drifter1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level 1 is a file parsing / heap corruption bug, with C++ classes.

There is no need to mess around with heap exploitation, and C++ lends itself to relatively straight forward exploitation.

[SMASHING C++ VPTRS][] - Although keep in mind that compiler changes can influence how things are laid out.

When looking over the below code, keep in mind what needs to be done to enable debugging, and what SetBuffer does.

One last hint: In order to correctly overflow the objects / pointers, the allocation size will have to be similar to the class size ;) Even blindly messing around will lead to code execution sooner or later

  [SMASHING C++ VPTRS]: http://www.phrack.org/issues.html?issue=56&id=8

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 1 of 0–15, in the memory corruption stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

C++ object layout and vtable pointer (vptr) overwrites.

### Key ideas

- **Heap object layout.** C++ objects with virtual functions start with a pointer to a table of function addresses. Overwrite that pointer and the next virtual call goes where you choose.
- **No need for deep heap exploitation.** The page says that C++ lends itself to relatively straightforward exploitation here.
- **Allocation size.** To overflow into the right object, the allocation size has to be similar to the class size.
- **Debugging.** The page tells you to keep in mind what is needed to enable debugging and what `SetBuffer` does; read the source for both.
- **Reading.** "Smashing C++ VPTRs" is linked; note that compiler changes can influence the layout.

### How to approach it

1. Read the provided code and sketch which objects sit next to each other in memory.
2. Craft a file that overflows one into the other.
3. Test in `gdb` and choose a target for the redirected call.

### Why it matters

Virtual-call hijacking is behind many browser and application exploits.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter0/">Level 0</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
