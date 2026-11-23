---
title: "Natas Level 17"
description: "Natas Level 17 — the application gives no feedback at all; learn time-based blind SQL injection, where a deliberate delay is the answer."
excerpt: "Natas Level 17 — the application gives no feedback at all; learn time-based blind SQL injection, where a deliberate delay is the answer."
permalink: /docs/wargames/natas/natas17/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- natas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas17.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- natas
author: bamr87
nav_order: 17
sidebar_label: "Level 17"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas17
    URL:      http://natas17.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas17` and find the password for `natas18`.
</div>

### What this level teaches

Using response time as the only observable signal.

### Key ideas

- **Time as a channel.** If the page always looks the same, you can still make the database pause when a condition is true and measure how long the response takes.
- **Delay functions.** SQL dialects provide ways to sleep or run an expensive operation conditionally.
- **Noise.** Network jitter produces false positives, so choose a delay that is clearly larger than normal variation and consider repeating questionable guesses.

### How to approach it

1. Use the previous blind level as your template.
2. Replace "true/false in the page" with "slow/fast response".
3. Time each request in your script and choose a threshold carefully.

### How developers prevent it

Use parameterised queries, impose database query time limits, and alert on unusual response times.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas16/">Level 16</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas18/">Level 18</a></nav>

</section>

<!-- study-guide:end -->
