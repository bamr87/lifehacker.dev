---
title: "Vortex Level 20"
description: "Vortex Level 20 — exploit integer handling bugs in a remote application whose source is available."
excerpt: "Vortex Level 20 — exploit integer handling bugs in a remote application whose source is available."
permalink: /docs/wargames/vortex/vortex20/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex20.md
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
nav_order: 20
sidebar_label: "Level 20"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Remote Integer Fun
------------------
The source code for the exploitable application can be found in "/home/vortex20". You must login to [vortex.labs.overthewire.org][] to complete this level.

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex20`, obtain access to `vortex21`. The exploitable source is in `/home/vortex20`.
</div>

### What this level teaches

Integer overflows, sign confusion and length checks that go wrong.

### Key ideas

- **Source provided.** Read it carefully; every arithmetic operation on a length or index deserves scrutiny.
- **Integer pitfalls.** Wrap-around, signed versus unsigned comparison and truncation all turn safe-looking checks into bypassable ones.
- **Remote.** You interact over the network, so scripting and careful framing of data are essential.

### How to approach it

1. List each integer in the code with its type and where it is checked and used.
2. Find a value that passes the check but breaks the later use.
3. Build the network exchange to deliver it.

### Why it matters

Integer errors lead to buffer overflows in many real programs and are easy to overlook in review.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex19/">Level 19</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex21/">Level 21</a></nav>

</section>

<!-- study-guide:end -->
