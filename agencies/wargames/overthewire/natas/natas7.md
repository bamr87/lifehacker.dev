---
title: "Natas Level 7"
description: "Natas Level 7 — a page parameter chooses which file is shown; learn about path traversal and local file inclusion."
excerpt: "Natas Level 7 — a page parameter chooses which file is shown; learn about path traversal and local file inclusion."
permalink: /docs/wargames/natas/natas7/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas7.md
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
nav_order: 7
sidebar_label: "Level 7"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas7
    URL:      http://natas7.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas7` and find the password for `natas8`.
</div>

### What this level teaches

How an unvalidated filename parameter can be abused to read files the developer never meant to expose.

### Key ideas

- **Parameters name files.** A URL like `index.php?page=something` can cause the server to load a file by name.
- **Path traversal.** Sequences such as `../` move up directories, letting a request escape the intended folder.
- **Absolute paths.** Depending on how the server code is written, you may not even need traversal.
- **A hint is given.** The page source tells you where the password is stored; the stated location is the route.

### How to approach it

1. Look at how the pages link to each other and what parameter changes.
2. Read the source comment for the file location, then work out how to request it through the parameter.

### How developers prevent it

Never build file paths from user input. Map user choices to a fixed allow-list of identifiers and resolve paths on the server.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas6/">Level 6</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
