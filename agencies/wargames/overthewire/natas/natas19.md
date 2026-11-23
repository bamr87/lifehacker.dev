---
title: "Natas Level 19"
description: "Natas Level 19 — session IDs look random but encode the username; learn to see structure in what appears to be gibberish."
excerpt: "Natas Level 19 — session IDs look random but encode the username; learn to see structure in what appears to be gibberish."
permalink: /docs/wargames/natas/natas19/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas19.md
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
nav_order: 19
sidebar_label: "Level 19"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas19
    URL:      http://natas19.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas19` and find the password for `natas20`.
</div>

### What this level teaches

That apparent randomness may hide a predictable structure, which can be decoded and forged.

### Key ideas

- **Decoding the cookie.** Compare the cookie values you receive for different usernames and look for a pattern, for example a standard encoding of readable text.
- **Predictable plus enumerable.** Once the format is understood, building candidate values is a short script.
- **Same goal as before.** You are still after the administrator's session.

### How to approach it

1. Log in with several different usernames and compare the resulting cookie values.
2. Work out what is being encoded, and what part varies.
3. Generate candidates for the admin account and test them.

### How developers prevent it

Treat session IDs as opaque random tokens. Never derive them from user attributes.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas18/">Level 18</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas20/">Level 20</a></nav>

</section>

<!-- study-guide:end -->
