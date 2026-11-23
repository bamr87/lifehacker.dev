---
title: "Natas Level 30"
description: "Natas Level 30 — a Perl database call quotes a single value, but not when it receives a list; learn how SQL injection survives an escaping function."
excerpt: "Natas Level 30 — a Perl database call quotes a single value, but not when it receives a list; learn how SQL injection survives an escaping function."
permalink: /docs/wargames/natas/natas30/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas30.md
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
nav_order: 30
sidebar_label: "Level 30"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas30
    URL:      http://natas30.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas30` and find the password for `natas31`.
</div>

### What this level teaches

How a subtle API behaviour defeats escaping, and why parameter handling in CGI scripts matters.

### Key ideas

- **Escaping function.** `quote()` normally turns a string into a safe SQL literal.
- **Repeated parameters.** In Perl CGI, a parameter provided several times can become a list rather than a single value, which changes what other functions do with it.
- **Second argument.** The quote function can take an optional data type that changes how it formats the value.
- **Read the library docs.** The documented behaviour of `quote()` with its second argument matters.

### How to approach it

1. Read the script and find where your input reaches the query.
2. Look up how Perl CGI handles repeated parameters and what the quote function does with the extra argument.

### How developers prevent it

Use placeholders in prepared statements instead of escaping manually, and treat parameters as having a single expected type.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas29/">Level 29</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas31/">Level 31</a></nav>

</section>

<!-- study-guide:end -->
