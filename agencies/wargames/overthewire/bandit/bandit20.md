---
title: "Bandit Level 20"
description: "Bandit Level 20 — use a setuid binary to read a file owned by another user, and learn what the setuid permission bit means."
permalink: /docs/wargames/bandit/bandit20/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit20.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 20 — use a setuid binary to read a file owned by another user, and learn what the setuid permission bit means."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 20
sidebar_label: "Level 20"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
To gain access to the next level, you should use the setuid binary in the homedirectory. Execute it without arguments to find out how to use it. The password for this level can be found in the usual place (/etc/bandit\_pass), after you have used the setuid binary.

Helpful Reading Material
------------------------
- [setuid on Wikipedia][]

[setuid on Wikipedia]: https://en.wikipedia.org/wiki/Setuid

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit19`, find the password for `bandit20`.
</div>

### What this level teaches

How Unix lets a program run with its owner's privileges, and why that is both useful and dangerous.

### Key ideas

- **User IDs.** A process has a real UID (who started it) and an effective UID (whose permissions it uses for access checks).
- **setuid.** When a file has the setuid bit (shown as `s` in `ls -l`), running it makes the effective UID the file's owner. The classic example is `passwd`, which lets ordinary users update a root-owned file.
- **`id`** prints your current user and group IDs.
- **Boundary.** Every setuid program is a deliberate crack in the privilege wall, so it must be written very carefully.

### How to approach it

1. Look at the binary with `ls -l` and note the `s`.
2. Run it with no arguments, as the Level Goal suggests, and read how it wants to be used.
3. The password then sits in the usual place under `/etc/bandit_pass`.

### Why it matters

Hunting for setuid binaries (`find / -perm -4000`) is a standard step in Linux privilege escalation, both for attackers and for hardening audits.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit19/">Level 19</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit21/">Level 21</a></nav>

</section>

<!-- study-guide:end -->
