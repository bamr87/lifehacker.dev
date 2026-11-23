---
title: "Natas Level 22"
description: "Natas Level 22 — the server redirects you away, but still sends the page body; learn that a redirect does not stop the content from being delivered."
excerpt: "Natas Level 22 — the server redirects you away, but still sends the page body; learn that a redirect does not stop the content from being delivered."
permalink: /docs/wargames/natas/natas22/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas22.md
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
nav_order: 22
sidebar_label: "Level 22"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas22
    URL:      http://natas22.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas22` and find the password for `natas23`.
</div>

### What this level teaches

How HTTP redirects really work, and how browsers hide what the server sent.

### Key ideas

- **A redirect is a response.** The server answers with a status like 302 and a `Location` header, and may still include a body.
- **Browsers follow it automatically,** so you never see the body of the first response.
- **`curl` shows everything.** Tools that do not follow redirects, or that print them, reveal the full reply.
- **Server-side logic does not halt.** Code that sets a redirect but does not stop executing still produces output.

### How to approach it

1. Request the page without following redirects and read the whole response.
2. Study the source to learn which parameter triggers the privileged behaviour.

### How developers prevent it

Always stop execution after sending a redirect, and perform the authorisation check before generating any sensitive output.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas21/">Level 21</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas23/">Level 23</a></nav>

</section>

<!-- study-guide:end -->
