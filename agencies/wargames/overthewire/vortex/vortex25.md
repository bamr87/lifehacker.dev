---
title: "Vortex Level 25"
description: "Vortex Level 25 — a lost level kept for history, which paired a password-cracking task with an exploit."
excerpt: "Vortex Level 25 — a lost level kept for history, which paired a password-cracking task with an exploit."
permalink: /docs/wargames/vortex/vortex25/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex25.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
nav_order: 25
sidebar_label: "Level 25"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Crackploit
----------

This level seems to have been lost, but we leave its description here for historical reasons.


There are two challenges for this level. One is to work out the password for the binary (a dictionary search should get it), and then work how you can exploit the level. A world readable binary is in /levels/decode. You must login to [vortex.labs.overthewire.org][] to complete this level.

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** this level is described as lost; there is nothing to solve on the server.
</div>

### What this means

The page keeps its description for historical reasons. It describes two challenges: work out the password for a provided binary (a dictionary search should find it), then work out how to exploit the level.

### What you can learn from it

- **Dictionary attacks.** Trying likely words before brute force is much more efficient.
- **Two-stage challenges.** Authentication to a program is one problem, exploiting it afterwards another.
- **Practise elsewhere.** Reproduce the idea with a program of your own and an exploit exercise from another game.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex24/">Level 24</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex26/">Level 26</a></nav>

</section>

<!-- study-guide:end -->
