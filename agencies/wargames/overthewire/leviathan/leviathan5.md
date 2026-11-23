---
title: "Leviathan Level 5"
description: "Leviathan Level 5 — a setuid program reads a file from a fixed path; learn how symbolic links redirect it."
excerpt: "Leviathan Level 5 — a setuid program reads a file from a fixed path; learn how symbolic links redirect it."
permalink: /docs/wargames/leviathan/leviathan5/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan5.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
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
**Level map:** logged in as `leviathan5`, find the password for `leviathan6`.
</div>

### What this level teaches

How symbolic links ("symlinks") can trick a privileged program that trusts a predictable path.

### Key ideas

- **Symlinks.** A symlink is a small file that points at another path; `ln -s TARGET LINKNAME` creates one.
- **Following links.** When a privileged program opens a file, the operating system follows a symlink transparently, using the program's privileges, not yours.
- **Predictable paths.** Programs that use fixed names in shared directories like `/tmp` are open to this.
- **Trace to learn.** `ltrace` reveals the path the program opens.

### How to approach it

1. Run the program and under `ltrace` to find which file it tries to open.
2. Think about what that name could point at instead.

### Why it matters

Insecure use of temporary files is a classic source of local privilege escalation, which is why `mktemp` and unpredictable names exist.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../leviathan4/">Level 4</a><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
