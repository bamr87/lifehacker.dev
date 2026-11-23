---
title: "Bandit Level 16"
description: "Bandit Level 16 — talk to a TLS-encrypted service on localhost using openssl s_client."
permalink: /docs/wargames/bandit/bandit16/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit16.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 16 — talk to a TLS-encrypted service on localhost using openssl s_client."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 16
sidebar_label: "Level 16"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level can be retrieved by submitting the password of the current level to **port 30001 on localhost** using SSL/TLS encryption.

**Helpful note: Getting "DONE", "RENEGOTIATING" or "KEYUPDATE"? Read the "CONNECTED COMMANDS" section in the manpage.**

Commands you may need to solve this level
-----------------------------------------
ssh, telnet, nc, ncat, socat, openssl, s\_client, nmap, netstat, ss

Helpful Reading Material
------------------------
- [Secure Socket Layer/Transport Layer Security on Wikipedia][]
- [OpenSSL Cookbook - Testing with OpenSSL][]

[Secure Socket Layer/Transport Layer Security on Wikipedia]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[OpenSSL Cookbook - Testing with OpenSSL]: https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit15`, find the password for `bandit16`.
</div>

### What this level teaches

TLS, the encryption layer behind HTTPS, and how to speak it by hand.

### Key ideas

- **TLS wraps TCP.** The same text conversation takes place, but inside an encrypted, authenticated channel set up by a handshake.
- **Certificates.** A server proves its identity with a certificate. Lab servers often present self-signed ones, which `openssl s_client` reports but still lets you use.
- **`openssl s_client -connect HOST:PORT`** is a netcat-like client for TLS.
- **Surprising words.** If you see `KEYUPDATE` or `RENEGOTIATING`, `s_client` interpreted a line you sent as one of its own commands. Read the "CONNECTED COMMANDS" section of `man s_client` and look at the quiet-mode options.

### How to approach it

1. Connect to the port given and inspect the certificate details it prints.
2. Send the password and read the reply.
3. Compare this with the previous level to feel the difference between plain and encrypted channels.

### Why it matters

Debugging HTTPS, mail or API connections often means using `openssl s_client` to see what the server really presents.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit15/">Level 15</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit17/">Level 17</a></nav>

</section>

<!-- study-guide:end -->
