---
title: "Natas Level 5"
description: "Natas Level 5 — a login state is stored in a cookie the user can edit; learn to inspect and change cookies."
excerpt: "Natas Level 5 — a login state is stored in a cookie the user can edit; learn to inspect and change cookies."
permalink: /docs/wargames/natas/natas5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas5
    URL:      http://natas5.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas5` and find the password for `natas6`.
</div>

### What this level teaches

How cookies carry state between requests, and the danger of storing trust decisions in them.

### Key ideas

- **Cookies.** Small name-value pairs the server asks the browser to store and return with every request.
- **Visible and editable.** The developer tools show all cookies for the site, and you can change them or send your own.
- **State must be verified.** If the server simply believes a cookie that says you are authorised, anyone can claim that.

### How to approach it

1. Look at the page's message about your status, then check the cookies the browser holds for this site.
2. Think about what value would change the server's decision.

### How developers prevent it

Keep authorisation state on the server and give the client only an unguessable session identifier, or sign any data you must hand to the client.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas4/">Level 4</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
