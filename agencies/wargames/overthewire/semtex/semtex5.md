---
title: "Semtex Level 5"
description: "Semtex Level 5 — connect from ten different IP addresses, answer a challenge on each, and receive the password on a randomly chosen connection."
excerpt: "Semtex Level 5 — connect from ten different IP addresses, answer a challenge on each, and receive the password on a randomly chosen connection."
permalink: /docs/wargames/semtex/semtex5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Random Networking
-----------------
Make 10 connections to port 24027 from different IP's. On each connection you will receive a string of 10 ASCII characters. XOR this string with the Semtex5 password, character by character. Then send back the 10 characters followed by another string of exactly 10 characters which identifies you (can be anything within A-Z, a-z, 0-9). The first 10 characters that you send, are different on every connection, the last 10 have to be the same. If you do not send the correct string back within 5 seconds you are disconnected. Once connected with at least 10 different IP's You will receive the password on one connection, chosen randomly.

**Note:  Your connections time out in 2 minutes and you cannot connect from an IP that is still connected.  May the sockets be with you. **

Reading Material
----------------
- [Socks5 Request For Comment][]

[Socks5 Request For Comment]: http://www.faqs.org/rfcs/rfc1928.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the challenge service is on port 24027.
</div>

### What this level teaches

Working with multiple source addresses and a challenge-response protocol.

### Key ideas

- **Challenge-response.** Each connection sends ten ASCII characters that you must combine, character by character, with the Semtex 5 password using XOR, then send back along with your own identifier.
- **Timing.** You have five seconds to answer, and connections time out after two minutes.
- **Different IPs.** You cannot reuse an address that is still connected, so you need several exits, such as proxies.
- **Reading.** The SOCKS5 RFC is linked, as a way of routing connections through other hosts.

### How to approach it

1. Write and test the challenge-response handling on a single connection.
2. Route ten connections through different addresses, using SOCKS or SSH tunnels.
3. Keep them open until the password arrives.

### Why it matters

It shows how defences based on source IP can be circumvented with proxies.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex4/">Level 4</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
