---
title: Semtex
description: "Semtex is an older (currently offline) wargame of 13 levels on network programming, reverse engineering, buffer overflows and combinatorial analysis."
excerpt: "Semtex is an older (currently offline) wargame of 13 levels on network programming, reverse engineering, buffer overflows and combinatorial analysis."
permalink: /docs/wargames/semtex/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- semtex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- semtex
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Semtex
======


Semtex is offline.


Wargame?
--------
This network is a legal environment where you can learn coding/hacking techniques without destroying anything. You have to solve Semtex 0 to get a username/password for login. Once logged in, you have to make your way from one level to the next, each one containing a small security hole/feature that has been installed for you. Your mission is to find out how to exploit the weakness and to cause interesting behavior :)

Rules?
------
Well you can do anything you want on this box, code, hack, learn, ... its all there for gaining knowledge. Please refrain from DOS attacks of any kind, it ruins the fun of you and of others. As long as you behave, everything is possible.

Contribute?
-----------
This wargame is from the community for the community. If you want to contribute, send a level plus exploit to aton at packetdropped dot org.

**Network programming, reverse engineering, buffer overflows and combinatorial analysis.**

**Contact : [aton at packetdropped dot org][]**

[contact us via chat]: https://overthewire.org/information/chat.html
[aton at packetdropped dot org]: mailto:aton@packetdropped.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide describes what each Semtex level asks for, using the upstream level pages, without passwords or complete solutions.

### Status

The upstream page states that Semtex is offline. The pages here are therefore best read as a syllabus of ideas you can practise yourself, rather than a game you can currently connect to. Check the [upstream Semtex page](https://overthewire.org/wargames/semtex/) in case that changes.

### What Semtex teaches

The maintainers describe the game as a legal environment in which you solve small security holes or features, each installed for you, and learn coding and hacking techniques without destroying anything. The skills it names are network programming, reverse engineering, buffer overflows and combinatorial analysis. You are asked to refrain from denial-of-service attacks, because they ruin the fun for everyone else.

### Connecting (historically)

Level 0 gives you credentials for `semtex1`, used with SSH on port 2229 at `semtex.labs.overthewire.org`. Other levels refer to extra hosts and tools such as `/semtex/` and `/rdx/`.

### The skills ladder

| Levels | Theme | Core skills |
|--------|-------|-------------|
| 0 | Getting started | raw TCP, cleaning a data stream, executable formats |
| 1–4 | Reversing and tricks | encryption algorithms, function interception, brute force, `ptrace` |
| 5–6 | Network games | proxying, multiple source addresses, ICMP and raw sockets |
| 7–9 | Covert channels and tunnels | restricted shells, big-number maths, timing channels, ICMP tunnels |
| 10–12 | Protocol weaknesses | weak authentication schemes, process plumbing, race conditions |

### Skills to bring

C or Python, comfort with sockets (Beej's guide is linked from Level 0), the ability to read assembly, and willingness to write small tools for each level.

### Take-aways

Several levels teach ideas that are very relevant today: covert channels, ICMP tunnelling to bypass firewalls, weak challenge-response schemes and spoofed source addresses. Treat them as study cases, and only experiment on systems you own or are authorised to test.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="semtex0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
