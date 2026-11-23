---
title: "Drifter Level 6"
description: "Drifter Level 6 — a simple remote daemon with a format-string vulnerability, left in a deliberately vulnerable state."
excerpt: "Drifter Level 6 — a simple remote daemon with a format-string vulnerability, left in a deliberately vulnerable state."
permalink: /docs/wargames/drifter/drifter6/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter6.md
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
nav_order: 6
sidebar_label: "Level 6"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level 6 is a simple remote daemon with a particular vulnerability. In what I intended for this level, it is running in a vulnerable state :P

**Reading material:**

[Advances in format string exploitation][]

[Format String Technique][]

[Exploiting Format String Vulnerabilities][]

As usual when I grab random code and look over it, someone might want to tell the developer :P

  [Advances in format string exploitation]: http://www.phrack.org/archives/59/p59-0x07.txt
  [Format String Technique]: http://julianor.tripod.com/bc/NN-formats.txt
  [Exploiting Format String Vulnerabilities]: http://doc.bughunter.net/format-string/exploit-fs.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 6 of 0–15, in the remote daemons stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Remote format-string exploitation.

### Key ideas

- **Format strings** let an attacker read and write memory when user data is used as the format argument of a `printf`-style call.
- **Remote.** You will drive the exploit over the network.
- **Reading.** The page links "Advances in format string exploitation", "Format String Technique" and "Exploiting Format String Vulnerabilities".
- **Real-world note.** The author remarks that the code came from somewhere else and someone might want to tell the developer.

### How to approach it

1. Identify how your input reaches the formatting function.
2. Leak stack values to learn the layout.
3. Use a write specifier to alter the value or pointer that gives you control.

### Why it matters

It repeats the lesson that unvalidated formatting is dangerous, this time in a network service.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter5/">Level 5</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter7/">Level 7</a></nav>

</section>

<!-- study-guide:end -->
