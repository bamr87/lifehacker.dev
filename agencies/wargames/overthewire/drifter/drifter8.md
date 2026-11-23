---
title: "Drifter Level 8"
description: "Drifter Level 8 — a Phrack Search Daemon runs on the server without its GPLv2 source available, so bug hunting and custom shellcode may be needed."
excerpt: "Drifter Level 8 — a Phrack Search Daemon runs on the server without its GPLv2 source available, so bug hunting and custom shellcode may be needed."
permalink: /docs/wargames/drifter/drifter8/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter8.md
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
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Phrack Search Daemon is running on the server. Good luck finding bugs without the GPLv2 source! Some custom shellcoding may be required.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 8 of 0–15, in the remote daemons stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Finding vulnerabilities in a real program without source.

### Key ideas

- **Real software.** The service is a real search daemon for Phrack articles.
- **No source provided.** You must find the bug by reverse engineering, fuzzing or recalling published research.
- **Custom shellcode.** The page says some may be required, for instance because of character restrictions or the environment.

### How to approach it

1. Learn what the daemon does and how clients talk to it.
2. Fuzz its inputs and analyse the crashes.
3. Write the payload carefully for the constraints.

### Why it matters

This is close to genuine vulnerability research on a real codebase.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter7/">Level 7</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
