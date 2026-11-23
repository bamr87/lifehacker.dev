---
title: "Natas Level 6"
description: "Natas Level 6 — read the server-side logic the site exposes and follow it to a file that holds the secret, learning how sensitive includes leak."
excerpt: "Natas Level 6 — read the server-side logic the site exposes and follow it to a file that holds the secret, learning how sensitive includes leak."
permalink: /docs/wargames/natas/natas6/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas6.md
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
nav_order: 6
sidebar_label: "Level 6"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas6
    URL:      http://natas6.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas6` and find the password for `natas7`.
</div>

### What this level teaches

How reading source code shows you what the server compares your input against, and how that comparison value ends up exposed.

### Key ideas

- **Source disclosure.** The page offers its own source code. A good habit is to read every offered source file in full.
- **Include files.** Applications often keep configuration or secrets in a separate file that is loaded by the main script.
- **Reachable by URL.** If that file lies inside the web root, anyone can request it directly.

### How to approach it

1. Open the source and ask: what does the code compare my input to, and where does that value come from?
2. Fetch the referenced file by its path.

### How developers prevent it

Store secrets outside the web root or in environment variables, and give server-side includes extensions that the web server will not serve as text.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas5/">Level 5</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas7/">Level 7</a></nav>

</section>

<!-- study-guide:end -->
