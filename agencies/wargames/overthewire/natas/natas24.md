---
title: "Natas Level 24"
description: "Natas Level 24 — a password check uses strcmp, which behaves unexpectedly when it is given the wrong type of input; learn PHP type confusion."
excerpt: "Natas Level 24 — a password check uses strcmp, which behaves unexpectedly when it is given the wrong type of input; learn PHP type confusion."
permalink: /docs/wargames/natas/natas24/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas24.md
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
nav_order: 24
sidebar_label: "Level 24"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas24
    URL:      http://natas24.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas24` and find the password for `natas25`.
</div>

### What this level teaches

How unexpected input types can defeat a security comparison.

### Key ideas

- **Parameters can be arrays.** In PHP, a form field written like `name[]` arrives as an array, not a string.
- **Functions misbehave on the wrong type.** Passing an array where a string is expected produces a warning and a surprising return value.
- **Loose comparison of that value.** The check then treats the result as success.
- **Read the manual.** The PHP documentation for `strcmp` lists its return values.

### How to approach it

1. Work out what the code compares and how it interprets the result.
2. Consider what input types you can send that the developer did not imagine.

### How developers prevent it

Validate input types, use strict comparison, and modern PHP versions that raise errors when the wrong type is passed.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas23/">Level 23</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas25/">Level 25</a></nav>

</section>

<!-- study-guide:end -->
