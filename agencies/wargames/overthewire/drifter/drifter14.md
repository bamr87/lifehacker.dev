---
title: "Drifter Level 14"
description: "Drifter Level 14 — a vulnerability in a third-party library, with extra code present that may make exploiting it easier."
excerpt: "Drifter Level 14 — a vulnerability in a third-party library, with extra code present that may make exploiting it easier."
permalink: /docs/wargames/drifter/drifter14/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter14.md
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
nav_order: 14
sidebar_label: "Level 14"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

This level utilises code from several places. The main vulnerable code lies in a 3rd party library. The other code present may allow you to more easily gain code execution.

The library code can be found in /drifter/drifter14_src/

If you're feeling kind hearted, you may wish to tell the developer of the bugs you found in the library code :-)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 14 of 0–15, in the open-ended stage of the game. The page does not say which account you start as, so check with `id` after connecting. The library source is in `/drifter/drifter14_src/`.
</div>

### What this level teaches

Auditing third-party code and chaining it with the application around it.

### Key ideas

- **Supply-chain reality.** Applications inherit the bugs of the libraries they use.
- **Source supplied.** Read the library carefully for unchecked sizes and unsafe parsing.
- **Helper code.** The page says other code in the program may help you reach code execution more easily, for example by providing useful functions or leaks.
- **Responsible disclosure.** The author suggests telling the library's developer about any bugs you find.

### How to approach it

1. Map how the application calls the library.
2. Audit the library functions that handle your input.
3. Combine the bug with whatever else the program gives you.

### Why it matters

Vulnerable dependencies are one of the most common real-world risks.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter13/">Level 13</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter15/">Level 15</a></nav>

</section>

<!-- study-guide:end -->
