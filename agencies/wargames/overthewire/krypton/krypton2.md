---
title: "Krypton Level 2"
description: "Krypton Level 2 — break a Caesar cipher by feeding the provided encryption program known text and watching how it responds."
excerpt: "Krypton Level 2 — break a Caesar cipher by feeding the provided encryption program known text and watching how it responds."
permalink: /docs/wargames/krypton/krypton2/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- krypton
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/krypton2.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- krypton
author: bamr87
nav_order: 2
sidebar_label: "Level 2"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Info
----------
ROT13 is a simple substitution cipher.

Substitution ciphers are a simple replacement algorithm. In this example of a substitution cipher, we will explore a 'monoalphebetic' cipher. Monoalphebetic means, literally, "one alphabet" and you will see why.

This level contains an old form of cipher called a 'Caesar Cipher'. A Caesar cipher shifts the alphabet by a set number. For example:

    plain:  a b c d e f g h i j k ...
    cipher: G H I J K L M N O P Q ...

In this example, the letter 'a' in plaintext is replaced by a 'G' in the ciphertext so, for example, the plaintext 'bad' becomes 'HGJ' in ciphertext.

The password for level 3 is in the file krypton3. It is in 5 letter group ciphertext. It is encrypted with a Caesar Cipher. Without any further information, this cipher text may be difficult to break. You do not have direct access to the key, however you do have access to a program that will encrypt anything you wish to give it using the key. If you think logically, this is completely easy.

One shot can solve it!

Have fun.

Additional Information:

The `encrypt` binary will look for the keyfile in your current working directory. Therefore, it might be best to create a working direcory in /tmp and in there a link to the keyfile. As the `encrypt` binary runs setuid `krypton3`, you also need to give `krypton3` access to your working directory.

Here is an example:

    krypton2@melinda:~$ mktemp -d
    /tmp/tmp.Wf2OnCpCDQ
    krypton2@melinda:~$ cd /tmp/tmp.Wf2OnCpCDQ
    krypton2@melinda:/tmp/tmp.Wf2OnCpCDQ$ ln -s /krypton/krypton2/keyfile.dat
    krypton2@melinda:/tmp/tmp.Wf2OnCpCDQ$ ls
    keyfile.dat
    krypton2@melinda:/tmp/tmp.Wf2OnCpCDQ$ chmod 777 .
    krypton2@melinda:/tmp/tmp.Wf2OnCpCDQ$ /krypton/krypton2/encrypt /etc/issue
    krypton2@melinda:/tmp/tmp.Wf2OnCpCDQ$ ls
    ciphertext  keyfile.dat

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `krypton2`, decrypt the file that holds the password for `krypton3`.
</div>

### What this level teaches

A chosen-plaintext attack: if you can make a system encrypt text of your choice, you can learn its key.

### Key ideas

- **Caesar cipher.** A substitution cipher where the alphabet is shifted by a fixed amount, here with an unknown shift.
- **Encryption oracle.** The `encrypt` program encrypts anything you give it using the secret key.
- **Chosen plaintext.** Encrypting the full alphabet once shows exactly how every letter is transformed, which is enough to decrypt anything.
- **Practical setup.** The program looks for its key file in your current directory and runs as the next user, so it needs a working directory under `/tmp` with a link to the key and permissive directory permissions. The page walks you through an example.

### How to approach it

1. Follow the setup in the page text to be able to run `encrypt`.
2. Think about the smallest, most informative input to encrypt.
3. Use what you learn to build the reverse mapping and apply it to the password file.

### Why it matters

Any system that lets attackers encrypt, decrypt or sign arbitrary data is an oracle. Many real attacks, from padding oracles to the ECB cut-and-paste in Natas, use this idea.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../krypton1/">Level 1</a><a class="sg-index" href="../">Krypton overview</a><a class="sg-next" href="../krypton3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
