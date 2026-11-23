---
title: "Semtex Level 9"
description: "Semtex Level 9 — write a client that tunnels a TCP session through ICMP packets to get past a firewall."
excerpt: "Semtex Level 9 — write a client that tunnels a TCP session through ICMP packets to get past a firewall."
permalink: /docs/wargames/semtex/semtex9/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex9.md
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
nav_order: 9
sidebar_label: "Level 9"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Tunneling your firewall
-----------------------
How do you get data through a firewall that is blocking any tcp connection? You just don't use a tcp connection, but instead other packets, that might not be filtered. For example network maintenance protocols like ICMP.

There is a raw socket open on a yet unknown host that listens for icmp packets and forwards them to a tcp server that you cannot reach. Your job is to create a client that communicates with this icmp "server". If everything works, you find yourself in a shell on an unknown system, and can search for the password.

The protocol and the server, that is used by the ICMP tunnel is described in your home directory. If you manage to blackbox analyze it, then you can jump directly from semtex0 to semtex10 :)

You will have to use /rdx/rawwrapper. 

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** use `/rdx/rawwrapper` to talk to the ICMP "server"; the protocol is described in your home directory.
</div>

### What this level teaches

Protocol tunnelling over a protocol that firewalls often allow.

### Key ideas

- **Firewalls filter by protocol.** If TCP is blocked but ICMP is allowed, data can be wrapped inside ICMP packets.
- **Raw wrapper.** A helper lets you send and receive ICMP from an unprivileged account.
- **Black-box shortcut.** The page says that if you manage to analyse the protocol as a black box, you can jump directly from `semtex0` to `semtex10`.
- **A shell at the end.** A working tunnel lands you in a shell on an unknown system.

### How to approach it

1. Read the protocol document in your home directory.
2. Build a client that sends and receives framed data inside ICMP.
3. Use the tunnel to run commands and search for the password.

### Why it matters

ICMP and DNS tunnelling are well-known exfiltration techniques, and network monitoring tools look for them.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex8/">Level 8</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex10/">Level 10</a></nav>

</section>

<!-- study-guide:end -->
