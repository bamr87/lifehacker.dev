---
title: "Bandit Level 33"
description: "Bandit Level 33 — escape from a shell that converts everything you type to uppercase."
permalink: /docs/wargames/bandit/bandit33/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- bandit
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit33.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 33 — escape from a shell that converts everything you type to uppercase."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 33
sidebar_label: "Level 33"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
After all this `git` stuff, it's time for another escape. Good luck!

Commands you may need to solve this level
-----------------------------------------
sh, man

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit32`, find the password for `bandit33`.
</div>

### What this level teaches

How shell parameters and expansions work, by being forced to use only characters that survive uppercase conversion.

### Key ideas

- **Commands are case-sensitive.** `LS` is not `ls`, so a shell that upper-cases input rejects normal commands.
- **Special parameters.** The shell defines variables such as the name of the running shell and the number of arguments. These are written with symbols and digits that uppercase conversion cannot change.
- **Expansions** replace such a parameter with its value *before* the command runs, so you can obtain a lowercase command indirectly.
- Read the "Special Parameters" section of `man bash`.

### How to approach it

1. Log in and observe exactly what the restricted program does to your input.
2. Search the bash manual for parameters that are not letters.
3. Think about what program that parameter's value would run, and what you could do from there.

### Why it matters

Input filters and blocklists are routinely bypassed by features of the interpreter behind them. This is the mindset behind many web and shell injection techniques.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit32/">Level 32</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit34/">Level 34</a></nav>

</section>

<!-- study-guide:end -->
