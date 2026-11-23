---
title: "Behemoth Level 5"
description: "Behemoth Level 5 — a privileged program sends data over the network to localhost, so you must set up a listener to receive it."
excerpt: "Behemoth Level 5 — a privileged program sends data over the network to localhost, so you must set up a listener to receive it."
permalink: /docs/wargames/behemoth/behemoth5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/behemoth/behemoth5.md
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
nav_order: 5
sidebar_label: "Level 5"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `behemoth5`, find the password for `behemoth6`.
</div>

### What this level teaches

Understanding a program's network behaviour and writing a matching receiver.

### Key ideas

- **Observe the syscalls.** `strace` shows the program opening a file, creating a socket and sending data, including the destination address and port.
- **Datagram sockets.** UDP does not need a connection, so a listener simply receives whatever arrives.
- **Be the server.** Netcat can listen on the right port and protocol.
- **Race to be ready.** The listener must be running before the program sends.

### How to approach it

1. Trace the program to learn what it sends and where.
2. Start a listener on the right port and protocol in a second terminal or in the background.
3. Run the program and read what arrives.

### Why it matters

Programs that phone home or log over the network are everywhere, and knowing how to capture that traffic is a basic analysis step.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../behemoth4/">Level 4</a><a class="sg-index" href="../">Behemoth overview</a><a class="sg-next" href="../behemoth6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
