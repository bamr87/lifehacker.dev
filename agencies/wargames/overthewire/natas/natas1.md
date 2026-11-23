---
title: "Natas Level 1"
description: "Natas Level 1 — the same secret is hidden in the page, but the site tries to stop you viewing it; learn why client-side restrictions are not security."
excerpt: "Natas Level 1 — the same secret is hidden in the page, but the site tries to stop you viewing it; learn why client-side restrictions are not security."
permalink: /docs/wargames/natas/natas1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas1.md
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
nav_order: 1
sidebar_label: "Level 1"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas1
    URL:      http://natas1.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas1` and find the password for `natas2`.
</div>

### What this level teaches

A site can try to block "right click" or shortcuts, but cannot stop the browser giving you the data it already received.

### Key ideas

- **Client-side controls are advisory.** JavaScript that disables a menu runs on *your* machine, under your control.
- **Many ways in.** Developer-tools shortcuts, the browser menu, a `view-source:` URL prefix and `curl` all bypass the trick.
- **Think about trust.** The server cannot verify anything the browser claims to have done.

### How to approach it

1. Notice what the page says it prevents, and ask which other tools can fetch the same page.
2. Use a method that never involves the blocked action.

### How developers prevent it

Enforce security on the server. Client-side checks are useful for convenience and user experience only, never for access control.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas0/">Level 0</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
