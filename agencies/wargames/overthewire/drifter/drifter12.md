---
title: "Drifter Level 12"
description: "Drifter Level 12 — a remote-procedure-call style reverse-engineering challenge."
excerpt: "Drifter Level 12 — a remote-procedure-call style reverse-engineering challenge."
permalink: /docs/wargames/drifter/drifter12/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- drifter
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/drifter/drifter12.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- drifter
author: bamr87
nav_order: 12
sidebar_label: "Level 12"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Remote Procedure Call style reverse engineering fun :-)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Where it fits:** Drifter level 12 of 0–15, in the randomisation and reversing stage of the game. The page does not say which account you start as, so check with `id` after connecting.
</div>

### What this level teaches

Reverse engineering a protocol with an RPC flavour: request, function identifier, arguments, response.

### Key ideas

- **Protocol discovery.** Capture traffic and read the binary to learn the message format.
- **Function dispatch.** An RPC server maps identifiers to functions; one of them may do more than intended.
- **Write a client.** Reimplement the protocol so you can call functions freely.

### How to approach it

1. Observe a normal exchange with a packet capture or a loop-back test.
2. Read the server's dispatcher.
3. Experiment with each function, looking for unsafe behaviour.

### Why it matters

Custom binary protocols are a common attack surface for embedded and industrial software.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../drifter11/">Level 11</a><a class="sg-index" href="../">Drifter overview</a><a class="sg-next" href="../drifter13/">Level 13</a></nav>

</section>

<!-- study-guide:end -->
