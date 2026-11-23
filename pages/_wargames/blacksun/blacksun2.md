---
title: "Blacksun Level 2"
description: "Blacksun Level 2 — write a malicious POP3 server that triggers a vulnerability in a buggy mail-client library and gets a shell despite ASLR."
excerpt: "Blacksun Level 2 — write a malicious POP3 server that triggers a vulnerability in a buggy mail-client library and gets a shell despite ASLR."
permalink: /wargames/blacksun/blacksun2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/blacksun2.md
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
author: amr
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level2 is a test application from a [pop3 library][] that's pretty buggy. The idea is to write a pop3 server to trigger a vulnerability (pick any you like :p) in the code and get a shell.

**Notes**

-   -fpic -fPIC was added to the compile options to remote DT\_TEXTREL's :p
-   If you're feeling generous, perhaps drop the author a note about any bugs you find so that future versions of the library can be fixed.
-   ASLR remote fun!

Binary information

### Binary information

| Stack smashing protection (SSP):            | Disabled        							|
| Postition Independent Executable (PIE):     | Disabled        							|
| Address space layout randomisation (ASLR):  | Enabled 								|
| Non-executable pages:                       | None / disabled 							|
|--------------------------------------------:+:------------------------------------------------------------------------|
| Code Location:                              | /levels/2/libspopc-0.7, using poptest1.c, and associated library code 	|
|---------------------------------------------+-------------------------------------------------------------------------|
| Location:                                   | /levels/level2							 	|

  [pop3 library]: http://brouits.free.fr/libspopc/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** the test client is `/levels/level2`, built from the libspopc 0.7 sources in `/levels/2/`.
</div>

### What this level teaches

Attacking a client by controlling the server it talks to.

### Key ideas

- **The server is the attacker.** The test application connects to a POP3 server; you write that server and craft responses that trigger a bug in the parsing code.
- **Code auditing.** The challenge says to pick any vulnerability you like, so finding one comes first. Read the library source for unchecked lengths and copies.
- **Position-independent code.** The note about compile options means libraries use relocatable code, so addresses are randomised.
- **Remote and ASLR.** You must work out addresses without being able to attach a debugger to the live run.
- **Be generous.** The page suggests telling the library's author about any real bugs you find.

### How to approach it

1. Read the POP3 protocol basics and the library's response-handling code.
2. Build a minimal fake server that produces ordinary responses, then alter one field at a time.
3. Turn a crash into control of execution.

### Why it matters

Malicious servers attacking vulnerable clients (mail clients, browsers, update tools) are a major real-world attack class.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../blacksun1/">Level 1</a><a class="sg-index" href="../">Blacksun overview</a><a class="sg-next" href="../blacksun3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
