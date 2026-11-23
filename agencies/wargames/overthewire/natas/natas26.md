---
title: "Natas Level 26"
description: "Natas Level 26 — a cookie contains serialised PHP data the server later unserialises; learn how object injection can write files on the server."
excerpt: "Natas Level 26 — a cookie contains serialised PHP data the server later unserialises; learn how object injection can write files on the server."
permalink: /docs/wargames/natas/natas26/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas26.md
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
nav_order: 26
sidebar_label: "Level 26"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas26
    URL:      http://natas26.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas26` and find the password for `natas27`.
</div>

### What this level teaches

PHP object injection through unsafe deserialisation.

### Key ideas

- **Serialisation.** PHP converts objects to strings and back; the conversion can call special "magic" methods such as a destructor.
- **User-controlled objects.** If the server unserialises a cookie, the client chooses which class is created and with what values.
- **Gadgets.** An existing class in the application (here, a logger) does something dangerous when its destructor runs.
- **Read the source.** Every class definition you need is visible.

### How to approach it

1. Study how the drawing feature stores state in the cookie.
2. Find a class whose methods perform file operations with data it holds.
3. Build a serialised object of that class, encode it as the cookie expects, and send it.

### How developers prevent it

Never unserialise untrusted data. Use a data-only format such as JSON and validate it.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas25/">Level 25</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas27/">Level 27</a></nav>

</section>

<!-- study-guide:end -->
