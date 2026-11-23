---
title: "Bandit Level 27"
description: "Bandit Level 27 — you already have a shell as bandit26; use a setuid helper in its home directory to read the next password."
permalink: /docs/wargames/bandit/bandit27/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit27.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 27 — you already have a shell as bandit26; use a setuid helper in its home directory to read the next password."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 27
sidebar_label: "Level 27"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
Good job getting a shell! Now hurry and grab the password for bandit27!

Commands you may need to solve this level
-----------------------------------------
ls

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit26`, find the password for `bandit27`.
</div>

### What this level teaches

Recognising a pattern you have met before: the setuid binary from Level 20 again, this time as your route to the next user.

### Key ideas

- **Reuse patterns.** After a hard level, the follow-up can be easy, provided you recognise what you are looking at.
- **`ls -l`** shows an `s` in the permissions of a setuid file and who owns it.
- **How the helper behaves.** Run it with no arguments to see what it expects.

### How to approach it

1. List your home directory and spot the setuid program.
2. Work out, from its usage message, how to make it act as `bandit27` on your behalf.
3. Use it to read the file in `/etc/bandit_pass`.

### Why it matters

Mature administrators know "how do I run one command as another user" by heart: `sudo`, setuid helpers and `su` all follow the same idea.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit26/">Level 26</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit28/">Level 28</a></nav>

</section>

<!-- study-guide:end -->
