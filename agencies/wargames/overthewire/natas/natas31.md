---
title: "Natas Level 31"
description: "Natas Level 31 — a CSV upload feature passes a file handle to Perl's diamond operator; learn how that can read arbitrary files."
excerpt: "Natas Level 31 — a CSV upload feature passes a file handle to Perl's diamond operator; learn how that can read arbitrary files."
permalink: /docs/wargames/natas/natas31/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas31.md
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
nav_order: 31
sidebar_label: "Level 31"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas31
    URL:      http://natas31.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas31` and find the password for `natas32`.
</div>

### What this level teaches

How a language feature meant for convenience becomes a file read vulnerability when input is user-controlled.

### Key ideas

- **The diamond operator.** In Perl, `<>` reads from files named on the command line or from standard input, and its handling of special names is surprising.
- **CGI file uploads.** An upload parameter can be either a file or a plain string depending on how the request is built.
- **Dual nature of a value.** The script treats a value as a file handle in one place and as a name in another.
- **Read the documentation.** Perl's `perlop` description of `<>` and `<<>>` explains the behaviour.

### How to approach it

1. Study how the script reads the uploaded file.
2. Work out how to make the same parameter mean something different to the second use.

### How developers prevent it

Use the safe double-diamond form, avoid reading from user-supplied names, and test upload handling with unexpected input shapes.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas30/">Level 30</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas32/">Level 32</a></nav>

</section>

<!-- study-guide:end -->
