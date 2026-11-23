---
title: "Bandit Level 14"
description: "Bandit Level 14 — authenticate to SSH with a private key instead of a password."
permalink: /docs/wargames/bandit/bandit14/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit14.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 14 — authenticate to SSH with a private key instead of a password."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 14
sidebar_label: "Level 14"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in **/etc/bandit\_pass/bandit14 and can only be read by user bandit14**. For this level, you don't get the next password, but you get a private SSH key that can be used to log into the next level. Look at the commands that logged you into previous bandit levels, and find out how to use the key for this level.

Commands you may need to solve this level
-----------------------------------------
ssh, scp, umask, chmod, cat, nc, install

Helpful Reading Material
------------------------
- [SSH/OpenSSH/Keys][]

[SSH/OpenSSH/Keys]: https://help.ubuntu.com/community/SSH/OpenSSH/Keys

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit13`, gain access to `bandit14`.
</div>

### What this level teaches

Public-key authentication, the way professionals actually log in to servers.

### Key ideas

- **Key pairs.** A private key stays secret with you; the matching public key sits on the server. The server proves you hold the private key without the key ever crossing the network.
- **Strict permissions.** `ssh` refuses to use a private key that other users can read, printing "UNPROTECTED PRIVATE KEY FILE". Keys need mode `600`.
- **`ssh -i FILE`** names the identity (private key) to use.
- **Copying files.** `scp` copies files over SSH, and the same server can also connect back to itself.

### How to approach it

1. Find the key in your home directory and look at its permissions.
2. Decide whether you will use the key from your own machine or from the server, and make the file permissions correct wherever it lives.
3. Log in as the next user, then read that user's password from the location the Level Goal gives. You will need that password for the next level.

### Why it matters

Passwords get guessed and phished; keys are far harder to steal remotely. Almost every cloud server and Git host uses SSH keys.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit13/">Level 13</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit15/">Level 15</a></nav>

</section>

<!-- study-guide:end -->
