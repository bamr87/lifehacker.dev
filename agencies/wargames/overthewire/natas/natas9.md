---
title: "Natas Level 9"
description: "Natas Level 9 — user input is passed into a shell command; learn what OS command injection is and why shell metacharacters are dangerous."
excerpt: "Natas Level 9 — user input is passed into a shell command; learn what OS command injection is and why shell metacharacters are dangerous."
permalink: /docs/wargames/natas/natas9/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas9.md
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
nav_order: 9
sidebar_label: "Level 9"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas9
    URL:      http://natas9.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas9` and find the password for `natas10`.
</div>

### What this level teaches

How building a shell command from user input lets the user add commands of their own.

### Key ideas

- **Shell metacharacters.** Characters such as `;`, `|` and `&` have special meaning and let a user chain additional commands.
- **Reading the source.** The page shows its code, including the exact command string it builds; it is the key to everything.
- **Where the password lives.** Natas keeps each level's password in `/etc/natas_webpass/`, which the web user for this level can read.

### How to approach it

1. Read the PHP source and write down the command it constructs from your input.
2. Think about what input would end that command and start another.

### How developers prevent it

Avoid shelling out. If you must, pass arguments as separate parameters without a shell, validate against an allow-list and escape the rest.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas8/">Level 8</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas10/">Level 10</a></nav>

</section>

<!-- study-guide:end -->
