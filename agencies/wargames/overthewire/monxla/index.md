---
title: "Monxla (HES 2012)"
description: "Monxla is a released conference wargame from Hackito Ergo Sum 2012 that you boot from a live CD image, set around a fictitious crime family."
excerpt: "Monxla is a released conference wargame from Hackito Ergo Sum 2012 that you boot from a live CD image, set around a fictitious crime family."
permalink: /docs/wargames/monxla/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- monxla
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/monxla/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- index
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

[RELEASED] Monxla (HES2012)
===========================

This wargame was introduced at the [Hackito Ergo Sum (HES)][HES] 2012 conference in Paris and is centered around the **fictitious Russian crime family Nasenko**.

As of November 2012, the Monxla game has been released to the public and can be downloaded [here][DownloadMonxla].

The following instructions are also included on the livecd:


[HES]: http://hackitoergosum.org/
[DownloadMonxla]: http://images.overthewire.org/Monxla%20-%20OverTheWire%20Wargame.iso

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains what Monxla is and how to run it safely. It does not describe the challenges.

### What it is

Monxla was introduced at the Hackito Ergo Sum (HES) conference in Paris in 2012 and is centred on a fictitious Russian crime family. Since November 2012 it has been released to the public as a downloadable `.iso` image, which is a live CD: it boots straight into the game without installing anything.

### How to play

Boot the ISO in a virtual machine (or from a burned disc). The upstream page says the instructions are included on the live CD, so read them first. A live system keeps its changes in memory, so reboot to reset the environment.

### Getting started

1. Download the ISO from the link on the page.
2. Create a new virtual machine and attach the ISO as its boot disc.
3. Read the instructions provided on the live system and begin.

### Run it safely

- **Isolate the network.** These images are intentionally vulnerable. Use a host-only or internal network in your hypervisor so the machine is not reachable from the internet or your home network.
- **Snapshot before you start.** A snapshot lets you roll back after you break something.
- **Use a disposable environment.** A spare virtual machine host, not the laptop that holds your real data.
- **Change default credentials** if you ever connect a lab image to a shared network.
- **Keep notes.** Story-driven games reward writing down every credential, host and clue as you find it.

### Where this fits

A live-CD game suits players who like self-contained puzzles that can be reset with a reboot, after finishing several of the main OverTheWire games.

</section>

<!-- study-guide:end -->
