---
title: "Bandit Level 7"
description: "Bandit Level 7 — search the whole server with find for a file owned by a given user and group, and silence permission errors."
permalink: /docs/wargames/bandit/bandit7/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- bandit
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit7.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 7 — search the whole server with find for a file owned by a given user and group, and silence permission errors."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 7
sidebar_label: "Level 7"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored **somewhere on the server** and has all of the following properties:
-   owned by user bandit7
-   owned by group bandit6
-   33 bytes in size

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html) , [grep](https://manpages.ubuntu.com/manpages/noble/man1/grep.1.html)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit6`, find the password for `bandit7`.
</div>

### What this level teaches

Using `find` on the entire filesystem with ownership filters, and handling the flood of "Permission denied" messages that results.

### Key ideas

- **Ownership.** Every file has an owning user and group; `find` can filter on both with `-user` and `-group`.
- **Standard streams.** Programs write results to stdout (file descriptor 1) and errors to stderr (2). Redirecting stderr with `2>/dev/null` discards the noise without hiding results.
- **`/dev/null`** is a special file that swallows everything written to it.
- **Search scope.** Starting from `/` means every directory you cannot read produces an error.

### How to approach it

1. Combine ownership and size tests, starting your search at `/`.
2. Redirect only stderr, so genuine results stay visible.
3. Read the single remaining match.

### Why it matters

Tracking down files by owner is how administrators audit permissions, and redirection is the basis of every shell pipeline you will write.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit6/">Level 6</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit8/">Level 8</a></nav>

</section>

<!-- study-guide:end -->
