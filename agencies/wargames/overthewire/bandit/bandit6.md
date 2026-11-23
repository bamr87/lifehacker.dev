---
title: "Bandit Level 6"
description: "Bandit Level 6 — use find to locate a file by size and permissions in a directory tree."
permalink: /docs/wargames/bandit/bandit6/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit6.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 6 — use find to locate a file by size and permissions in a directory tree."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 6
sidebar_label: "Level 6"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in a file somewhere under the **inhere** directory and has all of the following properties:
-   human-readable
-   1033 bytes in size
-   not executable

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit5`, find the password for `bandit6`.
</div>

### What this level teaches

Searching a directory tree by properties instead of by name, with `find`.

### Key ideas

- **`find PATH tests`** walks a tree and prints entries matching every test you list. Tests include `-type f` (regular files), `-size` and `-executable`.
- **Size units matter.** In `-size`, a suffix selects the unit and a missing suffix means 512-byte blocks, not bytes. Check `man find` for the byte suffix before trusting a result.
- **Negation.** A leading `!` inverts a test, which is how you say "not executable".
- Tests are combined with an implicit AND.

### How to approach it

1. Start broad (`find inhere -type f`) and add one test at a time, watching the output shrink.
2. When exactly one file remains, check it with `file` before reading it.

### Why it matters

Locating files by size, owner or modification time is core incident-response work, for example finding recently changed files or unexpected setuid binaries.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit5/">Level 5</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit7/">Level 7</a></nav>

</section>

<!-- study-guide:end -->
