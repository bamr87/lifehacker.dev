---
title: "Semtex Level 7"
description: "Semtex Level 7 — escape a restricted shell, then analyse the multivitamin algorithm for a weakness that makes it easy to defeat."
excerpt: "Semtex Level 7 — escape a restricted shell, then analyse the multivitamin algorithm for a weakness that makes it easy to defeat."
permalink: /docs/wargames/semtex/semtex7/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex7.md
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
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Multi-vitamin
-------------
Getting out of the restricted shell shouldn't take you more than
five minutes. Then have a look at /rdx/multivitamin. Try to analyse
the algorithm very carefully. There is a weakness that really speeds
up your quest...\

**Multiplication is easy, and so is division...?** You might want to look at [http://gmplib.org/][] if you use c.



[http://gmplib.org/]: http://gmplib.org/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** analyse the program in `/rdx/multivitamin` after leaving the restricted shell.
</div>

### What this level teaches

Restricted-shell escapes and cryptanalysis of an arithmetic scheme.

### Key ideas

- **Restricted shells.** The page says getting out should take about five minutes. Many programs offer ways to run other commands.
- **Study the algorithm carefully.** The page says a weakness really speeds up the solution.
- **Big numbers.** The hint "multiplication is easy and so is division...?" and the link to the GMP library suggest arithmetic on very large numbers.

### How to approach it

1. Get out of the restricted environment.
2. Read the algorithm and identify which operation is easy to reverse.
3. Use a big-number library to implement the attack.

### Why it matters

Number-theoretic schemes are only as strong as the hardness of the underlying problem, and misuse can destroy that hardness.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex6/">Level 6</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
