---
title: "Vortex Level 9"
description: "Vortex Level 9 — \"BlackBox\": the page gives no information, so log in and investigate the level yourself."
excerpt: "Vortex Level 9 — \"BlackBox\": the page gives no information, so log in and investigate the level yourself."
permalink: /docs/wargames/vortex/vortex9/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex9.md
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
nav_order: 9
sidebar_label: "Level 9"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

BlackBox
--------
There is no information available for this level. Login to [vortex.labs.overthewire.org][] and check it out.

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex9`, obtain access to `vortex10`.
</div>

### What this level teaches

Exploring an unknown level with nothing but your own reconnaissance.

### Key ideas

- **Black-box testing.** You see inputs and outputs but not the design.
- **Recon checklist.** Look at the home directory, `/vortex/`, file types and permissions, any setuid binary, and run the program with various inputs.
- **Make hypotheses.** State what you think it does, and design a test that could prove you wrong.

### How to approach it

1. Log in to `vortex.labs.overthewire.org` as the level's user and list everything relevant.
2. Use `file`, `strings` and `ltrace`.
3. Keep detailed notes of observed behaviour.

### Why it matters

Penetration testers frequently begin with exactly this: no documentation and a deadline.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex8/">Level 8</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex10/">Level 10</a></nav>

</section>

<!-- study-guide:end -->
