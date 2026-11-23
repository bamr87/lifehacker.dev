---
title: "Vortex Level 14"
description: "Vortex Level 14 — analyse a captured network exchange that uses weak encryption and recover the secret by classifying and dividing the problem."
excerpt: "Vortex Level 14 — analyse a captured network exchange that uses weak encryption and recover the secret by classifying and dividing the problem."
permalink: /docs/wargames/vortex/vortex14/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- vortex
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/vortex/vortex14.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- vortex
author: bamr87
nav_order: 14
sidebar_label: "Level 14"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Bad Encryption
--------------
Based on something seen in the "real world", it has weak encryption usage, used over a TCP/IP connection. This level requires you to apply some logic to the challenge at hand. You must login to [vortex.labs.overthewire.org][] to complete this level.

The \> indicates traffic "from the server, to the client", and the < indicates traffic "from the client, to the server".

If you need some hints, consider how you can divide and conquer the problem. For example, does it look like symmetric encryption, or asymmetric encryption? How can you further classify them?

[vortex.labs.overthewire.org]: ssh://vortex.labs.overthewire.org:2228

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `vortex14`, obtain access to `vortex15`.
</div>

### What this level teaches

Analysing an unknown protocol and breaking weak encryption.

### Key ideas

- **Real-world flaw.** The level is based on something seen in the wild: weak encryption used over TCP/IP.
- **Notation.** In the traffic shown, one marker means data from the server to the client and the other means client to server.
- **Classify first.** The page suggests asking whether it looks like symmetric or asymmetric encryption, and then narrowing further.
- **Divide and conquer.** Break the message into parts and identify what each part does.

### How to approach it

1. Study the captured exchange: lengths, repeated patterns and structure.
2. Form a hypothesis about the algorithm and test it on pieces of the data.
3. Build a decryptor or a forged message.

### Why it matters

Home-made protocols and weak ciphers are still found in devices and legacy software.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../vortex13/">Level 13</a><a class="sg-index" href="../">Vortex overview</a><a class="sg-next" href="../vortex15/">Level 15</a></nav>

</section>

<!-- study-guide:end -->
