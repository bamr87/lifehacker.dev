---
title: "Natas Level 21"
description: "Natas Level 21 — two related sites share one session store; learn how an application you can influence can poison a more trusted one."
excerpt: "Natas Level 21 — two related sites share one session store; learn how an application you can influence can poison a more trusted one."
permalink: /docs/wargames/natas/natas21/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas21.md
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
nav_order: 21
sidebar_label: "Level 21"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas21
    URL:      http://natas21.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas21` and find the password for `natas22`.
</div>

### What this level teaches

Trust boundaries between co-located applications, and session sharing across them.

### Key ideas

- **Shared session store.** The page mentions a second, "experimenter" site that runs next to this one and can set session data.
- **Parameter-to-session mapping.** The experimenter application copies request parameters into the session without limiting which ones.
- **Cookie scope.** The browser decides when to send a cookie, and you can copy a value from one site's request to another.

### How to approach it

1. Visit the linked second site and study how it uses your input.
2. Think about which session value the main site uses to grant access.
3. Make the second site write that value into a session you then use on the first.

### How developers prevent it

Separate session stores for separate trust levels, and never copy arbitrary request parameters into session state.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas20/">Level 20</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas22/">Level 22</a></nav>

</section>

<!-- study-guide:end -->
