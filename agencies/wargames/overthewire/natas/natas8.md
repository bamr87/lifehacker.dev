---
title: "Natas Level 8"
description: "Natas Level 8 — reverse a chain of encodings found in the source to work out the secret, and learn that obfuscation is not encryption."
excerpt: "Natas Level 8 — reverse a chain of encodings found in the source to work out the secret, and learn that obfuscation is not encryption."
permalink: /docs/wargames/natas/natas8/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas8.md
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
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas8
    URL:      http://natas8.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas8` and find the password for `natas9`.
</div>

### What this level teaches

Reading code that stores a secret in a transformed form, and undoing the steps.

### Key ideas

- **Encoding chains.** The code applies several reversible functions (such as hexadecimal conversion, string reversal and Base64) to the secret before storing it.
- **Reverse the order.** If the program applies steps in sequence A, B, C, you undo them as C, B, A.
- **PHP functions.** The manual page for each function states exactly what it does, and PHP has a counterpart that reverses most of them.
- **Run it yourself.** A small script, or an online PHP sandbox, is the easiest way to check each step.

### How to approach it

1. Read the stored value and the function chain.
2. Write the inverse operations in reverse order and test them on a sample.

### How developers prevent it

Use proper hashing for passwords (a slow, salted hash) so that nothing needs to be reversible, and never store secrets in source code.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas7/">Level 7</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
