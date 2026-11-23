---
title: "Bandit Level 15"
description: "Bandit Level 15 — talk to a plain-text network service on localhost with netcat."
permalink: /docs/wargames/bandit/bandit15/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit15.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 15 — talk to a plain-text network service on localhost with netcat."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 15
sidebar_label: "Level 15"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level can be retrieved by submitting the password of the current level to **port 30000 on localhost**.

Commands you may need to solve this level
-----------------------------------------
ssh, telnet, nc, openssl, s\_client, nmap

Helpful Reading Material
------------------------
- [How the Internet works in 5 minutes (YouTube)][] (Not completely
accurate, but good enough for beginners)
- [IP Addresses][]
- [IP Address on Wikipedia][]
- [Localhost on Wikipedia][]
- [Ports][]
- [Port (computer networking) on Wikipedia][]

[How the Internet works in 5 minutes (YouTube)]: https://www.youtube.com/watch?v=7_LPdttKXPc
[IP Addresses]: https://computer.howstuffworks.com/web-server5.htm
[IP Address on Wikipedia]: https://en.wikipedia.org/wiki/IP_address
[Localhost on Wikipedia]: https://en.wikipedia.org/wiki/Localhost
[Ports]: https://computer.howstuffworks.com/web-server8.htm
[Port (computer networking) on Wikipedia]: https://en.wikipedia.org/wiki/Port_(computer_networking)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit14`, find the password for `bandit15`.
</div>

### What this level teaches

What a network service is, and how to talk to one directly.

### Key ideas

- **Client and server.** A server listens on a port; a client connects and exchanges data. Here you are the client.
- **`localhost`** (`127.0.0.1`) means "this very machine", which makes it ideal for safe practice.
- **TCP.** A reliable byte stream. Many simple protocols are just lines of text.
- **`nc` (netcat)** opens a TCP connection and connects it to your keyboard and screen, so you can type to a service like a human protocol client.

### How to approach it

1. Connect to the port the Level Goal gives.
2. Send the previous level's password followed by a newline, and read the reply.
3. Notice that anyone on the network path could read this exchange because it is unencrypted. The next level fixes that.

### Why it matters

Every protocol you know (HTTP, SMTP, Redis) is text over a port, and netcat is the debugging tool for all of them.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit14/">Level 14</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit16/">Level 16</a></nav>

</section>

<!-- study-guide:end -->
