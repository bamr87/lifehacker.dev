---
title: "Narnia Level 0"
description: "Narnia Level 0 — overflow a buffer to overwrite a neighbouring variable and learn how data is laid out in memory."
excerpt: "Narnia Level 0 — overflow a buffer to overwrite a neighbouring variable and learn how data is laid out in memory."
permalink: /docs/wargames/narnia/narnia0/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- narnia
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia0.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- narnia
author: bamr87
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia0`, find the password for `narnia1`.
</div>

### What this level teaches

The simplest memory bug: writing more data than a buffer holds so that it spills into the next variable.

### Key ideas

- **Adjacent variables.** Local variables sit next to each other on the stack, so overflowing one can change another.
- **Little-endian values.** The target value must be written into memory least-significant byte first.
- **Printing bytes you cannot type.** A `printf` or `perl -e 'print ...'` command can emit arbitrary bytes for you.
- **Keeping the shell open.** The program may run a shell that exits immediately if its input ends; read about how to keep standard input open.

### How to approach it

1. Read the source and note the size of the buffer, the other variable and the check that depends on it.
2. Find the exact number of bytes needed to reach that variable and what value it must hold.
3. Send the input from a command and keep the connection open so the shell stays usable.

### Why it matters

Overwriting an adjacent flag, length or permission field is a real-world pattern as well as a teaching one.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
