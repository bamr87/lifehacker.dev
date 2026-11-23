---
title: "Natas Level 4"
description: "Natas Level 4 — the server decides who you are from the Referer header, which you control; learn to craft and modify HTTP requests."
excerpt: "Natas Level 4 — the server decides who you are from the Referer header, which you control; learn to craft and modify HTTP requests."
permalink: /docs/wargames/natas/natas4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas4
    URL:      http://natas4.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas4` and find the password for `natas5`.
</div>

### What this level teaches

That HTTP request headers are user-controlled, so any decision based on them is a weak one.

### Key ideas

- **Request headers.** Besides the URL, a browser sends headers such as `User-Agent`, `Cookie` and `Referer` (sic) describing the request.
- **The Referer header** says which page you came from. Servers sometimes use it as a crude access check.
- **You can send any header.** `curl -H` and a proxy let you set values the browser would not.

### How to approach it

1. Read what the page tells you about where it expects you to come from.
2. Use a tool that lets you set the header yourself, then request the page again.

### How developers prevent it

Never use a client-supplied header as proof of identity or origin. Use real authentication and authorisation checks.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas3/">Level 3</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
