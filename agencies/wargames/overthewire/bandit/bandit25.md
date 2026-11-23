---
title: "Bandit Level 25"
description: "Bandit Level 25 — brute-force a 4-digit PIN against a network service by scripting 10,000 guesses over one connection."
permalink: /docs/wargames/bandit/bandit25/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit25.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 25 — brute-force a 4-digit PIN against a network service by scripting 10,000 guesses over one connection."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 25
sidebar_label: "Level 25"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
A daemon is listening on port 30002 and will give you the password for
bandit25 if given the password for bandit24 and a secret numeric 4-digit pincode.
There is no way to retrieve the pincode except by going through all of the 10000
combinations, called brute-forcing.  
You do not need to create new connections each time

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit24`, find the password for `bandit25`.
</div>

### What this level teaches

How brute force works, when it is feasible, and how to automate it with a shell loop.

### Key ideas

- **Search space.** A four-digit PIN has 10,000 possibilities; at that size, exhaustive search is practical.
- **Loops.** Shell `for` loops, `seq` and `printf` can generate every candidate, and `printf '%04d'` pads with leading zeros (so `7` becomes `0007`).
- **One connection.** The Level Goal says you do not need a new connection for each guess, so you can pipe the whole stream into a single `nc`.
- **Defences.** Rate limiting, lockouts and longer secrets exist precisely to make this attack impractical.

### How to approach it

1. Test the protocol by hand with a few guesses to learn the exact input format.
2. Generate all 10,000 lines of the form the service expects, then send them in one go.
3. Filter the output so only the successful reply stands out.

### Why it matters

Understanding the arithmetic of brute force explains why short PINs, weak passwords and unthrottled login forms are dangerous.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit24/">Level 24</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit26/">Level 26</a></nav>

</section>

<!-- study-guide:end -->
