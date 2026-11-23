---
title: "Bandit Level 21"
description: "Bandit Level 21 — run your own network listener in the background so a setuid program can connect to it."
permalink: /docs/wargames/bandit/bandit21/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit21.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 21 — run your own network listener in the background so a setuid program can connect to it."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 21
sidebar_label: "Level 21"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a setuid binary in the homedirectory that does the following: it makes a connection to localhost on the port you specify as a commandline argument. It then reads a line of text from the connection and compares it to the password in the previous level (bandit20). If the password is correct, it will transmit the password for the next level (bandit21).

**NOTE:** Try connecting to your own network daemon to see if it works as you think

Commands you may need to solve this level
-----------------------------------------
ssh, nc, cat, bash, screen, tmux, Unix 'job control' (bg, fg, jobs, &, CTRL-Z, ...)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit20`, find the password for `bandit21`.
</div>

### What this level teaches

Reversing the client and server roles, and juggling several things at once in one terminal.

### Key ideas

- **Listening.** `nc -l PORT` waits for someone to connect (the exact syntax varies between netcat versions, so check `man nc`). Think of it as building a tiny server by hand.
- **The role flip.** This time the setuid program is the client; you provide the server.
- **Job control.** Press Ctrl-Z to suspend a command, `bg` to continue it in the background, `fg` to bring it back, `jobs` to list. Adding `&` at the end of a command starts it in the background.
- **Alternatives.** A second SSH session, `tmux` or `screen` solve the same problem by giving you multiple terminals.

### How to approach it

1. Start a listener that will send the current password to whatever connects.
2. Launch the setuid program pointing at your listener's port.
3. Read what the program sends back; as the Level Goal says, test your listener on its own first to be sure it behaves as you expect.

### Why it matters

Reverse connections, callbacks and test servers are everyday techniques for debugging networks and, in security, for understanding how malware communicates.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit20/">Level 20</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit22/">Level 22</a></nav>

</section>

<!-- study-guide:end -->
