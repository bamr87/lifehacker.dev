---
title: "Narnia Level 5"
description: "Narnia Level 5 — a format-string bug; learn how printf-style functions can be made to read and write arbitrary memory."
excerpt: "Narnia Level 5 — a format-string bug; learn how printf-style functions can be made to read and write arbitrary memory."
permalink: /docs/wargames/narnia/narnia5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/narnia/narnia5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `narnia5`, find the password for `narnia6`.
</div>

### What this level teaches

Format-string vulnerabilities.

### Key ideas

- **Why it happens.** Passing a user-controlled string as the *format* argument lets the user include conversion specifiers such as `%x` and `%n`.
- **Reading memory.** `%x` and positional specifiers like `%7$x` print values from the stack.
- **Writing memory.** `%n` stores the number of characters printed so far at an address taken from the stack, so you can control what is written and where.
- **Address placement.** You put the target address in your own input and find its position on the stack.
- **Reading material.** Scut's format string paper, referenced in the Blacksun reading list, is the classic.

### How to approach it

1. Read the source to see what value must change and how the format string is used.
2. Print stack values until you find your own input, to learn its position.
3. Combine padding and `%n` to write the value you need.

### Why it matters

Format-string bugs were once everywhere. Compilers now warn about them, but the technique teaches how arbitrary-write primitives work.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../narnia4/">Level 4</a><a class="sg-index" href="../">Narnia overview</a><a class="sg-next" href="../narnia6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
