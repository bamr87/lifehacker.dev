---
title: "Semtex Level 6"
description: "Semtex Level 6 — forge an ICMP packet with a spoofed source address using a raw socket helper."
excerpt: "Semtex Level 6 — forge an ICMP packet with a spoofed source address using a raw socket helper."
permalink: /docs/wargames/semtex/semtex6/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex6.md
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
nav_order: 6
sidebar_label: "Level 6"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

ICMP forging
------------
Send a special ICMP packet to an unknown host. Add the correct payload to it, to make sure you can receive the password. Spoof your origin address and make semtex believe, the packet is really coming from some government server (\*.gov) Make sure this server you are sending from has a reverse DNS entry, otherwise you will not receive an answer.

You find more specific information in your home directory. ** Note: You will have to use /semtex/semtexraw. Take a look at the source**

Reading Material
----------------
- [ICMP Request For Comment][]
- [Mixter's raw socket tutorial][]



[ICMP Request For Comment]: http://www.faqs.org/rfcs/rfc792.html
[Mixter's raw socket tutorial]: http://mixter.void.ru/rawip.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the helper is `/semtex/semtexraw`; more instructions are in your home directory.
</div>

### What this level teaches

Raw sockets, ICMP and source-address spoofing.

### Key ideas

- **ICMP.** The protocol behind `ping`, used for network control messages.
- **Raw sockets.** They let a program craft packets, including headers; this normally requires special privilege, which is why a helper is provided.
- **Spoofing.** The page asks you to make the packet appear to come from a `.gov` server and notes that your sending host needs a reverse DNS entry.
- **Reading.** The ICMP RFC and a raw socket tutorial are linked.

### How to approach it

1. Read the helper's source and the instructions in your home directory.
2. Build the ICMP message with the required payload.
3. Send it and listen for the reply.

### Why it matters

Spoofing is the basis of reflection attacks, and source address validation is the defence.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex5/">Level 5</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex7/">Level 7</a></nav>

</section>

<!-- study-guide:end -->
