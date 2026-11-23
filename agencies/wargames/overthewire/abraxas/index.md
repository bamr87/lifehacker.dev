---
title: "Abraxas (HES 2011)"
description: "Abraxas is a released conference wargame from Hackito Ergo Sum 2011 that you download as a virtual machine and play locally around a fictitious company."
permalink: /docs/wargames/abraxas/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- abraxas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/abraxas/index.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Abraxas is a released conference wargame from Hackito Ergo Sum 2011 that you download as a virtual machine and play locally around a fictitious company."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

[RELEASED] Abraxas (HES2011)
============================

This wargame was introduced at the [Hackito Ergo Sum (HES)][HES] 2011 conference in Paris and is centered around the **fictitious company dildosfromspace.com**

The wargame has its own website with the entire backstory. You can find it [here][backstory].

As of September 2011, the Abraxas game has been released to the public and can be downloaded [here][DownloadAbraxas].

The following instructions are also included on the diskimage:



[HES]: http://hackitoergosum.org/
[DownloadAbraxas]: http://images.overthewire.org/Abraxas%20-%20OverTheWire%20Wargame.ova
[backstory]: http://agent7a69.blogspot.com

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains what Abraxas is and how to run it safely. It does not describe the challenges, which are meant to be discovered.

### What it is

Abraxas was introduced at the Hackito Ergo Sum (HES) conference in Paris in 2011. It is centred on a fictitious company, and the game has its own website containing the whole backstory. Since September 2011 it has been released to the public and can be downloaded as an `.ova` virtual-machine image from the OverTheWire image server.

### How it differs from the SSH games

Games such as Bandit and Narnia run on OverTheWire servers. Abraxas runs on your own computer: you import the virtual machine and play entirely offline. Instructions for the game are included on the disk image itself, which is why the upstream page ends with a heading and nothing below it.

### Getting started

1. Download the OVA file from the link on the page (it is a large file; verify the download completes).
2. Import it into VirtualBox or another hypervisor that supports OVA.
3. Read the instructions on the image and the backstory website, then start investigating.

### Run it safely

- **Isolate the network.** These images are intentionally vulnerable. Use a host-only or internal network in your hypervisor so the machine is not reachable from the internet or your home network.
- **Snapshot before you start.** A snapshot lets you roll back after you break something.
- **Use a disposable environment.** A spare virtual machine host, not the laptop that holds your real data.
- **Change default credentials** if you ever connect a lab image to a shared network.
- **Keep notes.** Story-driven games reward writing down every credential, host and clue as you find it.

### Where this fits

Conference wargames suit people who have already completed several of the main games, such as Bandit, Natas and Narnia, and want story-driven, multi-step challenges.

</section>

<!-- study-guide:end -->
