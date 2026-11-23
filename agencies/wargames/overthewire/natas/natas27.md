---
title: "Natas Level 27"
description: "Natas Level 27 — a registration and login system that compares trimmed values; learn how database column truncation can create a duplicate account."
excerpt: "Natas Level 27 — a registration and login system that compares trimmed values; learn how database column truncation can create a duplicate account."
permalink: /docs/wargames/natas/natas27/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas27.md
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
nav_order: 27
sidebar_label: "Level 27"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas27
    URL:      http://natas27.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas27` and find the password for `natas28`.
</div>

### What this level teaches

How the database and the application disagree about what a username is.

### Key ideas

- **Column limits.** A column stores only so many characters; longer values may be silently cut, depending on the database mode.
- **Padding and trimming.** Trailing spaces may be ignored in comparisons.
- **Two views of the same string.** The application checks for an existing user using the full value, while the database stores a shortened one.
- **Impersonation.** A crafted registration can yield a second account that the lookup treats as the original.

### How to approach it

1. Read the register and lookup logic and note every length and comparison.
2. Design an input that passes the "does it exist?" check yet is stored as the target name.
3. Log in as the new account and see what the application returns.

### How developers prevent it

Enforce uniqueness in the database with a unique constraint, normalise input before checking it, and run the database in strict mode so that over-long values are rejected rather than truncated.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas26/">Level 26</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas28/">Level 28</a></nav>

</section>

<!-- study-guide:end -->
