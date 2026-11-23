---
title: "Semtex Level 10"
description: "Semtex Level 10 — exploit a weakness in how an authentication daemon checks passwords, in the style of old Windows 95/98 network shares."
excerpt: "Semtex Level 10 — exploit a weakness in how an authentication daemon checks passwords, in the style of old Windows 95/98 network shares."
permalink: /docs/wargames/semtex/semtex10/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex10.md
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
nav_order: 10
sidebar_label: "Level 10"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Hacking szene
-------------
**Thanks to zaphod and Mush for finding a bugs in this level**

Do you know these hacking movies where they push some buttons, then the evil hacker script window turns up and a percentage bar is showing how far the password cracking has gone?


    0%....10%....20%....30%....40%....50%....60%....70%....80%....90%....100%
    password cracked!

Ever wanted to do it yourself? Here is your chance.\

This level implements a weakness in the authentication scheme used by M$ win95 and win98 for the netbios shares.

There is a TCP daemon on brebera port 24019. It authenticates your password. Once you send the correct password, it echoes it back. Well, let the source speak for itself. As far as brute force may take you, a little brain is never bad :P Perhaps you have heard of pqwak?

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the daemon listens on port 24019 of the Semtex network host; its source is provided.
</div>

### What this level teaches

How a flawed authentication scheme lets you recover a password far faster than brute force.

### Key ideas

- **Movie hacking.** The page jokes about the progress-bar password crackers from films.
- **The weakness.** It mirrors a real flaw in Windows 95 and 98 network shares, where a password could be verified in pieces, so each part can be guessed separately.
- **Source provided.** Study how the daemon compares your input and what it reveals.
- **Brain over brawn.** The page notes brute force goes only so far, then mentions a tool called pqwak.

### How to approach it

1. Read the source and note how the comparison is done and what feedback you get.
2. Design an attack that learns the password one part at a time.
3. Script it and watch the answer appear.

### Why it matters

Comparison functions that reveal how much of a guess was right are a real weakness; use constant-time comparison and rate limiting.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex9/">Level 9</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex11/">Level 11</a></nav>

</section>

<!-- study-guide:end -->
