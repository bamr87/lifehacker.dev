---
title: "Natas Level 18"
description: "Natas Level 18 — session identifiers come from a small number space; learn how predictable session IDs can be brute-forced to hijack an admin session."
excerpt: "Natas Level 18 — session identifiers come from a small number space; learn how predictable session IDs can be brute-forced to hijack an admin session."
permalink: /docs/wargames/natas/natas18/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas18.md
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
nav_order: 18
sidebar_label: "Level 18"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas18
    URL:      http://natas18.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas18` and find the password for `natas19`.
</div>

### What this level teaches

Why session identifiers must be large, random and unpredictable.

### Key ideas

- **Sessions.** After login the server gives you an identifier in a cookie, and that identifier alone proves who you are.
- **Small space.** If IDs are just small numbers, an attacker can try them all and eventually find an authenticated admin.
- **Scripting.** Loop over the possible values, set the cookie and look for a change in the response.

### How to approach it

1. Read the source and work out the range of session IDs the application can issue.
2. Write a loop that sends each candidate in the session cookie.
3. Detect success by a distinctive difference in the reply.

### How developers prevent it

Use long cryptographically random session IDs from your framework, rotate them at login, expire them and bind them to additional checks where appropriate.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas17/">Level 17</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas19/">Level 19</a></nav>

</section>

<!-- study-guide:end -->
