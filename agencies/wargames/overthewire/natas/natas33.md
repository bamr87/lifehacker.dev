---
title: "Natas Level 33"
description: "Natas Level 33 — an upload checker and a file function combine so that a crafted archive triggers deserialisation; learn about PHP phar attacks."
excerpt: "Natas Level 33 — an upload checker and a file function combine so that a crafted archive triggers deserialisation; learn about PHP phar attacks."
permalink: /docs/wargames/natas/natas33/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas33.md
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
nav_order: 33
sidebar_label: "Level 33"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas33
    URL:      http://natas33.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas33` and find the password for `natas34`.
</div>

### What this level teaches

How seemingly harmless file functions can trigger object deserialisation.

### Key ideas

- **Phar archives.** PHP can read an archive format called phar, which stores serialised metadata.
- **Stream wrappers.** File functions accept URL-like paths such as `phar://...`; opening one can cause the metadata to be unserialised automatically.
- **Gadget in the source.** A class in the page code performs an unsafe action when it is destroyed.
- **Building a phar.** PHP's `Phar` class lets you create one with your own metadata, if the build is allowed in your environment.

### How to approach it

1. Read the upload and checking code carefully, and find the class that does something interesting.
2. Work out how to get your file to the server and make a file function open it as a phar.

### How developers prevent it

Disallow `phar://` for user-controlled paths, update PHP, and avoid dangerous classes that act on destruction.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas32/">Level 32</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas34/">Level 34</a></nav>

</section>

<!-- study-guide:end -->
