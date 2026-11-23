---
title: "Natas Level 20"
description: "Natas Level 20 — a custom session file handler trusts a newline in user input; learn how data written to server-side state can be forged."
excerpt: "Natas Level 20 — a custom session file handler trusts a newline in user input; learn how data written to server-side state can be forged."
permalink: /docs/wargames/natas/natas20/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas20.md
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
nav_order: 20
sidebar_label: "Level 20"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas20
    URL:      http://natas20.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas20` and find the password for `natas21`.
</div>

### What this level teaches

How custom serialisation formats create injection bugs.

### Key ideas

- **Session storage.** Server-side sessions keep a small file or record of values keyed by the session ID.
- **Line-based format.** The handler writes one `key value` pair per line, so a newline in your input looks like a new entry.
- **Two requests.** The application reads the session at the start of a request, so a poisoned write on one request can take effect on the next.
- **Read the code.** The source for the custom `myread` and `mywrite` handlers is the whole puzzle.

### How to approach it

1. Read how a value you supply ends up inside the stored session.
2. Think about what a line break lets you add.
3. Make the first request to write the data, and the second to benefit from it.

### How developers prevent it

Use your framework's well-tested session handlers, and encode data (for example JSON) instead of inventing a format that can be broken by delimiters.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas19/">Level 19</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas21/">Level 21</a></nav>

</section>

<!-- study-guide:end -->
