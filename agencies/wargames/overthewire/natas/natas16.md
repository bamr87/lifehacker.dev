---
title: "Natas Level 16"
description: "Natas Level 16 — command injection returns, but with stricter filtering and no visible output; learn to turn a search tool into a yes/no oracle."
excerpt: "Natas Level 16 — command injection returns, but with stricter filtering and no visible output; learn to turn a search tool into a yes/no oracle."
permalink: /docs/wargames/natas/natas16/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas16.md
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
nav_order: 16
sidebar_label: "Level 16"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas16
    URL:      http://natas16.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas16` and find the password for `natas17`.
</div>

### What this level teaches

Blind command injection through whatever characters the filter still allows.

### Key ideas

- **Shell expansion.** A shell evaluates certain constructs before running the command, so you can influence what runs without using the blocked characters.
- **Side-channel output.** The page still shows whether a word was found, which is the oracle.
- **Building on earlier levels.** The method resembles Level 15, applied to a shell command.
- **Automation.** Guess the secret one character at a time with a script.

### How to approach it

1. Compare this filter with the one from Level 10 and list the characters that are still allowed.
2. Look up what those allowed characters can still do inside the command you saw.
3. Use the page's reply as a true/false signal and automate the guessing.

### How developers prevent it

As with all injection bugs: separate data from code. Do not pass user input through a shell at all.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas15/">Level 15</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas17/">Level 17</a></nav>

</section>

<!-- study-guide:end -->
