---
title: "Natas Level 15"
description: "Natas Level 15 — the application only answers \"exists\" or \"does not exist\"; learn blind boolean SQL injection and how to automate it."
excerpt: "Natas Level 15 — the application only answers \"exists\" or \"does not exist\"; learn blind boolean SQL injection and how to automate it."
permalink: /docs/wargames/natas/natas15/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas15.md
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
nav_order: 15
sidebar_label: "Level 15"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas15
    URL:      http://natas15.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas15` and find the password for `natas16`.
</div>

### What this level teaches

Extracting data one true/false question at a time when the application never prints query results.

### Key ideas

- **Blind injection.** You cannot see data, but you can see whether a condition was true.
- **Oracle.** Each request asks a yes/no question such as "does the password start with this letter?".
- **Binary search or character-by-character.** With a good strategy, a short script finds a 32-character password in a few hundred requests.
- **Automation.** Write the loop in Python with `requests` and `string.ascii_letters`; doing it by hand is impractical.

### How to approach it

1. Confirm the injection works by making the page answer differently for a true and a false condition.
2. Ask the database about one character at a time using functions such as `SUBSTRING` or `LIKE`.
3. Automate, and print progress as you go.

### How developers prevent it

Parameterised queries again, plus rate limiting and monitoring for bursts of near-identical requests.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas14/">Level 14</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas16/">Level 16</a></nav>

</section>

<!-- study-guide:end -->
