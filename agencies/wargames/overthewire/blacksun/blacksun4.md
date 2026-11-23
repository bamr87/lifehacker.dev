---
title: "Blacksun Level 4"
description: "Blacksun Level 4 — exploit a deliberately introduced heap vulnerability in Apache and PHP by running your own PHP code on the server."
excerpt: "Blacksun Level 4 — exploit a deliberately introduced heap vulnerability in Apache and PHP by running your own PHP code on the server."
permalink: /docs/wargames/blacksun/blacksun4/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- blacksun
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/blacksun4.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- blacksun
author: bamr87
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

level4 is an installation of Apache and PHP with an introduced heap vulnerability.

The introduced vulnerability is as follows:



Thanks to orix for the introduced code snippet

The document root is in /levels/level4/htdocs, you'll need to put your php code there and call it via the webserver on port 55555.

**Note:** that if you're executing a shell, it can't be /bin/sh or /bin/bash, oh, and the apache process can't access the /etc/pass directory :P

### Binary information

| Stack smashing protection (SSP):            | Enabled         |
| Postition Independent Executable (PIE):     | Enabled         |
| Address space layout randomisation (ASLR):  | Enabled         |
| Non-executable pages:                       | None / disabled |
|--------------------------------------------:+:----------------|
| Location:                                   | 127.0.0.1:55555 |

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the service listens on `127.0.0.1:55555`, with the document root at `/levels/level4/htdocs`.
</div>

### What this level teaches

Exploiting a bug in an interpreter by writing scripts in the language it runs.

### Key ideas

- **Interpreter exploitation.** The vulnerability is in the PHP runtime, so your PHP code is the attack vector.
- **Heap memory.** PHP's allocator and the web server's heap layout determine what an overflow or free corrupts.
- **Constraints.** The page says the spawned shell cannot be `/bin/sh` or `/bin/bash`, and the Apache process cannot read certain paths, so your goal and payload must account for that.
- **All protections on.** SSP, PIE and ASLR are enabled, with non-executable pages off.

### How to approach it

1. Place a simple PHP file in the document root and request it through the web server on the stated port.
2. Study the introduced vulnerability described on the page and work out how to trigger it from PHP.
3. Iterate on heap layout until the corruption lands where you need it.

### Why it matters

Modern attacks often target interpreters and runtimes, and heap grooming is the key technique.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../blacksun3/">Level 3</a><a class="sg-index" href="../">Blacksun overview</a><span></span></nav>

</section>

<!-- study-guide:end -->
