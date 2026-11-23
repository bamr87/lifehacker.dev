---
title: "Behemoth Level 2"
description: "Behemoth Level 2 — a privileged program runs another program by name, so how it finds that program becomes the weakness."
excerpt: "Behemoth Level 2 — a privileged program runs another program by name, so how it finds that program becomes the weakness."
permalink: /docs/wargames/behemoth/behemoth2/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- behemoth
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/behemoth/behemoth2.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- behemoth
author: bamr87
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `behemoth2`, find the password for `behemoth3`.
</div>

### What this level teaches

How the `PATH` environment variable and the current directory influence which program gets executed.

### Key ideas

- **Commands run by name.** When a program calls a command without an absolute path, the system searches the directories in `PATH` in order.
- **Controlling the search.** If you can put your own program earlier in that search, your program runs with the caller's privileges.
- **Trace to see the call.** `strace` and `ltrace` show exactly what the program executes and in which directory it works.
- **Writable workspace.** Make a private directory under `/tmp` for your files.

### How to approach it

1. Trace the program and note every command it runs by name.
2. Think about what a replacement for that command should do with its privileges.
3. Make it findable and run the original program.

### Why it matters

Unsafe use of `system()` and relative commands in setuid programs is a long-standing source of privilege escalation.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../behemoth1/">Level 1</a><a class="sg-index" href="../">Behemoth overview</a><a class="sg-next" href="../behemoth3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
