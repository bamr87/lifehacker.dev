---
title: "Krypton"
description: "Krypton is a cryptography wargame of 7 levels that moves from Base64 and Caesar ciphers through frequency analysis and Vigenère to a weak stream cipher."
excerpt: "Krypton is a cryptography wargame of 7 levels that moves from Base64 and Caesar ciphers through frequency analysis and Vigenère to a weak stream cipher."
permalink: /docs/wargames/krypton/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-05-24T00:00:00.000Z'
author: bamr87
draft: false
categories:
- wargames
- security
- krypton
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
- cryptography
keywords:
- krypton wargame
- overthewire krypton
- classical ciphers
- rotary ciphers
- linux ctf
- cryptography practice
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/index.md
source_name: overthewire
license: MIT
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Krypton
=======

The Krypton wargame.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains the cryptography each level introduces and how to attack it in principle, but it never gives passwords or ready-made solutions.

### What Krypton teaches

Krypton is a short course in how classical ciphers are broken and why modern ones are built the way they are. Each level gives you a ciphertext (and sometimes a tool) and asks you to recover the next password. You will see substitution ciphers, polyalphabetic ciphers, known-plaintext attacks and finally a stream cipher with a weak random number generator.

### How to play

You log in over SSH to `krypton.labs.overthewire.org` on port 2231 as `krypton1`, using the password you derive from Level 0. The files for each level are in `/krypton/`, and the password for the next level is in a file named after it (for example `krypton2`). Because you cannot write in most places, create a working directory under `/tmp` with `mktemp -d`.

### How the levels are numbered

Level 0 contains the first password in encoded form. After that, the page for Level N tells you how to decrypt the file that holds the password for Level N+1.

### The skills ladder

| Level | Theme | Core idea |
|-------|-------|-----------|
| 0 | Encoding | Base64 is reversible and not secret |
| 1 | Rotation ciphers | ROT13 and the Caesar cipher |
| 2 | Chosen plaintext | an encryption oracle reveals the key |
| 3 | Frequency analysis | monoalphabetic substitution with several messages |
| 4 | Polyalphabetic | Vigenère with a known key length |
| 5 | Polyalphabetic | Vigenère with an unknown key length |
| 6 | Stream ciphers | XOR keystreams and a weak random generator |

### Key concepts

- **Plaintext, ciphertext, key.** The message, the scrambled form and the secret that controls scrambling.
- **Substitution vs transposition.** Replacing symbols versus rearranging them.
- **Frequency analysis.** In English, letters appear with predictable frequencies (E, T, A, O are common), and these survive monoalphabetic substitution.
- **Kerckhoffs's principle.** A cipher must stay secure even if everything about it, except the key, is public.
- **One-time pad.** A truly random key as long as the message and never reused is provably unbreakable, but impractical for most uses.

### Tools

`tr`, `fold`, `sort`, `uniq -c`, `bc`, Python, and graphical tools such as CrypTool. A spreadsheet or a short script for counting letters makes the middle levels much faster.

### Where this fits

Krypton is one of the three games suggested after Bandit. Its ideas return in Natas (for example the XOR cookie) and in any later work on authentication and encryption.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="krypton0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
