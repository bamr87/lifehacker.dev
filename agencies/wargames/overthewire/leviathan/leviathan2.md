---
title: "Leviathan Level 2"
description: "Leviathan Level 2 — a setuid program checks whether you may read a file before printing it; learn what that check really verifies."
excerpt: "Leviathan Level 2 — a setuid program checks whether you may read a file before printing it; learn what that check really verifies."
permalink: /docs/wargames/leviathan/leviathan2/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan2.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
author: bamr87
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `leviathan2`, find the password for `leviathan3`.
</div>

### What this level teaches

How a program decides whether you are allowed to read a file, and how the name it checks can differ from the file it finally opens.

### Key ideas

- **Check, then use.** Many programs test permission first and open the file afterwards. Anything that can change between the two steps is an opportunity.
- **File names are strings.** Spaces, symbolic links and relative paths all affect which file a name finally refers to.
- **Trace it.** `ltrace` shows the library calls used to check and open files.

### How to approach it

1. Run the program under `ltrace` with a file you own and watch its calls.
2. Compare what it checks with what it opens, and think about a name that means different things in each place.
3. Use a private directory under `/tmp` for your experiments.

### Why it matters

This class of bug, known as time-of-check to time-of-use, has caused real privilege escalations in widely used software.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../leviathan1/">Level 1</a><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
