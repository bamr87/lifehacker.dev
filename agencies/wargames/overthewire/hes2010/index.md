---
title: "HES2010"
description: "HES2010 is a released conference wargame from Hackito Ergo Sum 2010 that you run as a local virtual machine, with its own website inside the VM."
excerpt: "HES2010 is a released conference wargame from Hackito Ergo Sum 2010 that you run as a local virtual machine, with its own website inside the VM."
permalink: /docs/wargames/hes2010/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- hes2010
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/hes2010/index.md
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

[RELEASED] HES2010
==================

This wargame was introduced at the [Hackito Ergo Sum (HES)][HES] 2010 conference in Paris and is centered around the **fictitious company dirty-underwear.com**

The winners of this wargame at HES2010 were **CCCP and morla**.

As of January 2012, the HES2010 game has been released to the public and can be downloaded [here][DownloadHES2010].

The wargame has its own local website on the virtual machine. Once the VM is running, you can find it at http://192.168.66.66

The following instructions are also included on the diskimage:



[HES]: http://hackitoergosum.org/
[DownloadHES2010]: http://images.overthewire.org/HES2010 - OverTheWire Wargame.ova

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains what HES2010 is and how to run it safely. It does not describe the challenges.

### What it is

HES2010 was introduced at the Hackito Ergo Sum (HES) conference in Paris in 2010 and is centred on a fictitious company. The winners at the conference were the teams CCCP and morla. Since January 2012 it has been released to the public as a downloadable virtual-machine image (`.ova`).

### How to play

The game has its own local website on the virtual machine. Once the VM is running, the upstream page says you can find it at `http://192.168.66.66`. The same instructions are included on the disk image. Because the address is fixed, configure your hypervisor's network so that your host can reach that address, using a host-only network, and nothing else.

### Getting started

1. Download the image from the link on the page.
2. Import it into VirtualBox or another OVA-capable hypervisor.
3. Start the VM, open the local website in your browser and follow the story.

### Run it safely

- **Isolate the network.** These images are intentionally vulnerable. Use a host-only or internal network in your hypervisor so the machine is not reachable from the internet or your home network.
- **Snapshot before you start.** A snapshot lets you roll back after you break something.
- **Use a disposable environment.** A spare virtual machine host, not the laptop that holds your real data.
- **Change default credentials** if you ever connect a lab image to a shared network.
- **Keep notes.** Story-driven games reward writing down every credential, host and clue as you find it.

### Where this fits

A good follow-up once you are comfortable with web and Linux basics from Bandit and Natas, and want a themed, multi-stage scenario.

</section>

<!-- study-guide:end -->
