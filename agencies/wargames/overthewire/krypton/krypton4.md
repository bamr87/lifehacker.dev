---
title: "Krypton Level 4"
description: "Krypton Level 4 — break a Vigenère cipher when you know the key length, by treating each position as a separate Caesar problem."
excerpt: "Krypton Level 4 — break a Vigenère cipher when you know the key length, by treating each position as a separate Caesar problem."
permalink: /docs/wargames/krypton/krypton4/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/krypton/krypton4.md
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
nav_order: 4
sidebar_label: "Level 4"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Info
----------
Good job!

You more than likely used some form of FA and some common sense to solve that one.

So far we have worked with simple substitution ciphers. They have also been 'monoalphabetic', meaning using a fixed key, and giving a one to one mapping of plaintext (P) to ciphertext (C). Another type of substitution cipher is referred to as 'polyalphabetic', where one character of P may map to many, or all, possible ciphertext characters.

An example of a polyalphabetic cipher is called a Vigenère Cipher. It works like this:

If we use the key(K) 'GOLD', and P = PROCEED MEETING AS AGREED, then "add" P to K, we get C. When adding, if we exceed 25, then we roll to 0 (modulo 26).

    P P R O C E E D M E E T I N G A S A G R E E D\
    K G O L D G O L D G O L D G O L D G O L D G O\

becomes:

    P 15 17 14 2 4 4 3 12 4 4 19 8 13 6 0 18 0 6 17 4 4 3\
    K 6 14 11 3 6 14 11 3 6 14 11 3 6 14 11 3 6 14 11 3 6 14\
    C 21 5 25 5 10 18 14 15 10 18 4 11 19 20 11 21 6 20 2 8 10 17\

So, we get a ciphertext of:

    VFZFK SOPKS ELTUL VGUCH KR

This level is a Vigenère Cipher. You have intercepted two longer, english language messages (American English). You also have a key piece of information. You know the key length!

For this exercise, the key length is 6. The password to level five is in the usual place, encrypted with the 6 letter key.

Have fun!

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `krypton4`, decrypt the file that holds the password for `krypton5`.
</div>

### What this level teaches

Polyalphabetic ciphers and how knowing the key length turns them back into simple substitution.

### Key ideas

- **Vigenère.** A repeating keyword is added letter by letter to the plaintext, modulo 26, so one plaintext letter can encrypt to many different ciphertext letters. The page includes a worked example with the key `GOLD`.
- **Defeating the repetition.** With a key of length six, every sixth letter was shifted by the same amount. Splitting the text into six groups gives six independent Caesar ciphers.
- **Frequency analysis per group.** Each group is plain shifted English, so the most common letter is likely `E` (or another common letter) shifted.
- **Reassemble the key.** Once you know the shift for each group, you know the key and can decrypt everything.

### How to approach it

1. Combine the intercepted messages for more data and split them by position modulo the key length.
2. Count letters in each group and deduce each shift.
3. Decrypt and read the result; correct any group that gives gibberish.

### Why it matters

Vigenère was considered unbreakable for centuries. Once you know how it is attacked, the lesson sticks: repeated keys leak.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../krypton3/">Level 3</a><a class="sg-index" href="../">Krypton overview</a><a class="sg-next" href="../krypton5/">Level 5</a></nav>

</section>

<!-- study-guide:end -->
