---
title: "Bandit Level 0"
description: "Bandit Level 0 — log in to a remote Linux server over SSH on port 2220, the skill every other OverTheWire level builds on."
permalink: /docs/wargames/bandit/bandit0/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-10-16T22:30:54.000Z'
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit0.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 0 — log in to a remote Linux server over SSH on port 2220, the skill every other OverTheWire level builds on."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 0
sidebar_label: "Level 0"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The goal of this level is for you to log into the game using SSH. The host to which you need to connect is **bandit.labs.overthewire.org**, on port 2220. The username is **bandit0** and the password is **bandit0**. Once logged in, go to the [Level 1][] page to find out how to beat Level 1.

Commands you may need to solve this level
-----------------------------------------
[ssh](https://manpages.ubuntu.com/manpages/noble/man1/ssh.1.html)

Helpful Reading Material
------------------------
- [Secure Shell (SSH) on Wikipedia][]
- [How to use SSH with a non-standard port on It's FOSS][]
- [How to use SSH with ssh-keys on wikiHow][]

[Level 1]: {{ '/docs/wargames/bandit/bandit1/' | relative_url }}
[Secure Shell (SSH) on Wikipedia]: https://en.wikipedia.org/wiki/Secure_Shell
[How to use SSH with a non-standard port on It's FOSS]: https://itsfoss.com/ssh-to-port/
[How to use SSH with ssh-keys on wikiHow]: https://www.wikihow.com/Use-SSH

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** this is the starting line. You log in as `bandit0` (password `bandit0`); logging in successfully is the whole level.
</div>

### What this level teaches

How to open a secure remote shell. Almost everything in OverTheWire, and most real-world server administration, starts with SSH (Secure Shell): a client on your machine opens an encrypted connection to an SSH server and gives you a command line on the remote computer.

### Key ideas

- **Host** — the machine you connect to, here `bandit.labs.overthewire.org`.
- **Port** — a numbered door on that machine. SSH normally listens on 22, but this server uses 2220, so you must pass the port explicitly. Every OverTheWire game has its own port.
- **Credentials** — a username and password prove who you are. The terminal deliberately shows nothing while you type a password; that is normal, not a frozen screen.
- **Host key fingerprint** — the first time you connect, SSH asks whether to trust the server and remembers its fingerprint in `~/.ssh/known_hosts`. If the fingerprint ever changes, SSH warns you that someone may be impersonating the server.

### How to approach it

1. Open a terminal. macOS and Linux include `ssh`; recent Windows versions include it in Command Prompt and PowerShell, and PuTTY is a graphical alternative.
2. The command has the shape `ssh USER@HOST -p PORT`. Fill the three values in from the Level Goal and read the `-p` option in `man ssh` if you are unsure.
3. After logging in, run `whoami` and `pwd` to confirm who and where you are, then `exit` to disconnect. You will repeat this login dance for every level.

### Why it matters

SSH is how engineers administer servers, deploy code and tunnel traffic. Understanding hosts, ports and host-key verification is the foundation for everything that follows.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
