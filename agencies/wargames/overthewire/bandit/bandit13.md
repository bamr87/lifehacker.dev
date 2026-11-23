---
title: "Bandit Level 13"
description: "Bandit Level 13 — peel back layers of a hexdump, gzip, bzip2 and tar by repeatedly identifying and unpacking the file."
permalink: /docs/wargames/bandit/bandit13/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit13.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 13 — peel back layers of a hexdump, gzip, bzip2 and tar by repeatedly identifying and unpacking the file."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 13
sidebar_label: "Level 13"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

## Level Goal

The password for the next level is stored in the file **data.txt**, which is a hexdump of a file that has been repeatedly compressed. For this level it may be useful to create a directory under /tmp in which you can work. Use mkdir with a hard to guess directory name. Or better, use the command "mktemp -d". Then copy the datafile using cp, and rename it using mv (read the manpages!)

## Commands you may need to solve this level

grep, sort, uniq, strings, base64, tr, tar, gzip, bzip2, xxd, mkdir, cp, mv, file

## Helpful Reading Material

- [Hex dump on Wikipedia][]

[Hex dump on Wikipedia]: https://en.wikipedia.org/wiki/Hex_dump

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit12`, find the password for `bandit13`.
</div>

### What this level teaches

A repeatable loop for dealing with unknown, nested data: identify, unpack, repeat.

### Key ideas

- **Hexdump.** `xxd` shows bytes as hexadecimal; `xxd -r` reverses a dump back into the original binary.
- **Compression formats.** gzip, bzip2 and tar archives each begin with a recognisable signature, so `file` can name them at every layer.
- **Extension expectations.** `gzip -d` and `bzip2 -d` expect matching filename suffixes, so you will rename files with `mv` between steps.
- **A private working directory.** You cannot normally create files in your home directory. Make a new one under `/tmp` with `mktemp -d`, which picks a name nobody can guess, and copy the data file into it with `cp`.

### How to approach it

1. Reverse the hexdump into a file.
2. Run `file` on it, apply the matching tool, and run `file` on the result. Repeat until you see plain text.
3. Keep notes of the chain you followed; it is easy to lose your place.

### Why it matters

Malware droppers, CTF challenges and forensic images are frequently layered. A calm identify-and-unpack loop beats guessing.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit12/">Level 12</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit14/">Level 14</a></nav>

</section>

<!-- study-guide:end -->
