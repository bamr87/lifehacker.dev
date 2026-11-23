---
title: "Semtex Level 8"
description: "Semtex Level 8 — receive a file through a timing covert channel where delays between bytes stand for bytes that were never sent."
excerpt: "Semtex Level 8 — receive a file through a timing covert channel where delays between bytes stand for bytes that were never sent."
permalink: /docs/wargames/semtex/semtex8/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/semtex/semtex8.md
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
nav_order: 8
sidebar_label: "Level 8"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Non-sniffable data
------------------
This level is about some very simple covert channel, about transferring information that cannot possibly be sniffed. There is a socket file in /rdx/nature. It is a local Unix socket. Receive data from it until EOF and save it to a file.

Watch the time between the received bytes. Certain delays mean certain bytes that have been left out (have not been sent).

    0-1 s : no special data
    1-2 s : 'Q'
    2-3 s : 'L'
    3-4 s : 'A'
    4-5 s : 'V'

you have to take these "unsent" data into your output file too, exactly at the places where they occur.

Thus you are receiving data while not receiving anything.

The output file is a .jpg image :)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** read from the Unix socket `/rdx/nature` until end of file and save the result.
</div>

### What this level teaches

Covert channels: hiding data in timing so it cannot be sniffed as content.

### Key ideas

- **Timing channel.** The delay before each received byte encodes extra data: a pause in the 1–2 second range stands for one letter, 2–3 seconds another, and so on, as the page's table shows.
- **Reconstruct the data.** Insert the omitted characters exactly where the delays occurred.
- **The result.** The completed file is a JPEG image.
- **Local Unix socket.** A file-like endpoint for local inter-process communication.

### How to approach it

1. Write a reader that records the time between bytes.
2. Apply the table to insert the hidden bytes.
3. Verify the output with `file` and open the picture.

### Why it matters

Covert timing channels exist in real malware and in side-channel attacks.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../semtex7/">Level 7</a><a class="sg-index" href="../">Semtex overview</a><a class="sg-next" href="../semtex9/">Level 9</a></nav>

</section>

<!-- study-guide:end -->
