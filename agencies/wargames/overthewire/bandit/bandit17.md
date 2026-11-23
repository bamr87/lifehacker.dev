---
title: "Bandit Level 17"
description: "Bandit Level 17 — scan a range of ports with nmap, tell TLS from plain services, and find the one that returns credentials."
permalink: /docs/wargames/bandit/bandit17/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit17.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 17 — scan a range of ports with nmap, tell TLS from plain services, and find the one that returns credentials."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 17
sidebar_label: "Level 17"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The credentials for the next level can be retrieved by submitting the password of the current level to **a port on localhost in the range 31000 to 32000**. First find out which of these ports have a server listening on them. Then find out which of those speak SSL/TLS and which don't. There is only 1 server that will give the next credentials, the others will simply send back to you whatever you send to it.

**Helpful note: Getting "DONE", "RENEGOTIATING" or "KEYUPDATE"? Read the "CONNECTED COMMANDS" section in the manpage.**

Commands you may need to solve this level
-----------------------------------------
ssh, telnet, nc, ncat, socat, openssl, s\_client, nmap, netstat, ss

Helpful Reading Material
------------------------
- [Port scanner on Wikipedia][]

[Port scanner on Wikipedia]: https://en.wikipedia.org/wiki/Port_scanner

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit16`, find the credentials for `bandit17`.
</div>

### What this level teaches

Reconnaissance: finding which services are running and what they speak.

### Key ideas

- **Port scanning.** `nmap -p 31000-32000 localhost` tests each port in a range to see which are open.
- **Service detection.** Nmap's version-detection options probe open ports to guess whether they speak TLS or plain text.
- **Elimination.** Of the open ports, some are echo servers that repeat what you send; only one returns real credentials.
- **Credentials are not always passwords.** Here the reward is a private key. Save it to a new directory you create under `/tmp` and set strict permissions before using it.

### How to approach it

1. Scan only the range given and only `localhost`.
2. For each open port, try TLS first, then plain text, and watch the responses.
3. Write down which port did what; it helps you avoid repeating work.

### Why it matters

Mapping a target's attack surface is step one of every penetration test. The ethics rule applies: **scan only systems you own or have written permission to test.**

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit16/">Level 16</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit18/">Level 18</a></nav>

</section>

<!-- study-guide:end -->
