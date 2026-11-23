---
title: "Natas Level 3"
description: "Natas Level 3 — learn how robots.txt, meant to guide search engines, can instead point an attacker at the very paths you wanted hidden."
excerpt: "Natas Level 3 — learn how robots.txt, meant to guide search engines, can instead point an attacker at the very paths you wanted hidden."
permalink: /docs/wargames/natas/natas3/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas3.md
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
nav_order: 3
sidebar_label: "Level 3"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas3
    URL:      http://natas3.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas3` and find the password for `natas4`.
</div>

### What this level teaches

The `robots.txt` convention, and why it is a map for attackers rather than a lock.

### Key ideas

- **robots.txt** is a public text file at the root of a site that asks well-behaved crawlers not to visit certain paths.
- **Not enforced.** The file does nothing to stop a human; listing a path there advertises it.
- **Hints in page content.** The page's message about search engines is the clue to where the answer lives.

### How to approach it

1. Read the hint on the page and think about which standard file a site uses to talk to crawlers.
2. Open that file in the browser and follow any path it names.

### How developers prevent it

Never rely on robots.txt for secrecy. Protect sensitive areas with authentication, and do not list private paths in a public file.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas2/">Level 2</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas4/">Level 4</a></nav>

</section>

<!-- study-guide:end -->
