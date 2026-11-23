---
title: "Natas Level 29"
description: "Natas Level 29 — a Perl script opens a filename taken from the request; learn how Perl's open function can run commands."
excerpt: "Natas Level 29 — a Perl script opens a filename taken from the request; learn how Perl's open function can run commands."
permalink: /docs/wargames/natas/natas29/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas29.md
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
nav_order: 29
sidebar_label: "Level 29"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas29
    URL:      http://natas29.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas29` and find the password for `natas30`.
</div>

### What this level teaches

How features of a language runtime can turn a file parameter into command execution.

### Key ideas

- **Perl's `open`.** In its two-argument form, the string you provide is interpreted: certain characters make Perl run a command rather than open a file.
- **Filters.** The application tries to block obvious abuse, so the details of the filter matter.
- **Encoding.** URL-encoded characters can pass through places raw ones do not.
- **Not PHP.** The earlier levels were PHP; this one shows the same ideas in another language.

### How to approach it

1. Notice that the page parameter names a file, and read the Perl documentation for `open`.
2. Test what the filter blocks, then find a way to express the command you need.

### How developers prevent it

Use the three-argument form of `open` with an explicit mode, validate filenames, and never pass user input to the shell.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas28/">Level 28</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas30/">Level 30</a></nav>

</section>

<!-- study-guide:end -->
