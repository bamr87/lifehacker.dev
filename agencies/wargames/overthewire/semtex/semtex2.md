---
title: "Semtex Level 2"
description: "Semtex Level 2 — a program checks your user ID; trick it into seeing a different one using function interception."
excerpt: "Semtex Level 2 — a program checks your user ID; trick it into seeing a different one using function interception."
permalink: /docs/wargames/semtex/semtex2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex2.md
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
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Dynamic tricks
--------------
This program checks your user ID.
 
Perhaps you can trick it, so that it thinks you have a different one.
 
Think dynamically.

Reading Material
----------------
- [Link][]

[Link]: http://www.google.com/search?q=linux+function+interception

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the goal is to make the program believe you are a different user.
</div>

### What this level teaches

Dynamic tricks: changing a program's behaviour without changing the program.

### Key ideas

- **Library calls can be replaced.** On Linux, the dynamic linker can be told to load your own version of a function before the system's, so the program calls yours.
- **Think dynamically.** The page's hint is to think about what happens at run time rather than in the file on disk.
- **The reading link.** The page points you to a search about Linux function interception.
- **Limits.** Setuid programs ignore some of these mechanisms for safety; understanding which is part of the challenge.

### How to approach it

1. Find which function the program uses to learn the user ID.
2. Research function interception on Linux.
3. Build and test a small replacement.

### Why it matters

Interposition is used by profilers and debuggers as well as by malware.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex1/">Level 1</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
