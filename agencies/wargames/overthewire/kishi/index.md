---
title: "Kishi (HES 2013)"
description: "Kishi is a released conference wargame from Hackito Ergo Sum and No Such Con 2013, distributed as a Vagrant box with several LXC containers."
excerpt: "Kishi is a released conference wargame from Hackito Ergo Sum and No Such Con 2013, distributed as a Vagrant box with several LXC containers."
permalink: /docs/wargames/kishi/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- kishi
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/kishi/index.md
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

[RELEASED] Kishi (HES2013 and NSC2013)
======================================

This wargame was introduced at the [Hackito Ergo Sum (HES)][HES] 2013 and [No Such Con (NSC)][NSC] 2013 conferences in Paris and is centered around the **fictictious North-Korean cyberops training facility Kishi**

As of December 2014, the Kishi game has been released to the public and can be downloaded through [Vagrant] for VirtualBox by typing:

	vagrant init StevenVanAcker/kishi
	vagrant up

Kishi listens on ports 22, 80 and 2222, which are forwarded from the VM host through ports 6622, 6680 and 3322 respectively. Kishi uses several LXC containers internally, you can access them from the host VM through

	virsh -c lxc://

The SSH server running on port 2222 can be used to login to kishi itself with username/password vagrant/vagrant.  All containers run an SSH server with an admin account with username/password otw/otw.  These admin accounts are not part of the game and should only be used for setting up or debugging. Change their passwords if you connect the VM to a public network.

To start the game, visit Kishi's web server on port 80 (or port 6680 of the host).

[HES]: http://hackitoergosum.org/
[NSC]: http://nosuchcon.org
[Kishi]: http://kishi.labs.overthewire.org
[Vagrant]: https://www.vagrantup.com/
[vagrantcloud]: https://atlas.hashicorp.com/StevenVanAcker/boxes/kishi

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide explains how Kishi is built and how to run it safely. It does not describe the challenges.

### What it is

Kishi was introduced at the HES 2013 and No Such Con (NSC) 2013 conferences in Paris and is centred on a fictitious North Korean cyber-operations training facility. Since December 2014 it has been available to the public as a Vagrant box for VirtualBox.

### Starting it

The upstream page gives the two commands that create and boot the box:

```
vagrant init StevenVanAcker/kishi
vagrant up
```

Vagrant is a tool for creating reproducible virtual machines from a text description. `vagrant init` writes a configuration file, and `vagrant up` downloads the box and starts it.

### Network layout

Kishi listens on ports 22, 80 and 2222 inside the VM, which Vagrant forwards to your host as 6622, 6680 and 3322 respectively. Start the game by visiting Kishi's web server on port 80 (host port 6680) in your browser.

### Containers

Kishi runs several LXC containers internally, which you can inspect from the host VM with `virsh -c lxc://`. LXC containers are lightweight, isolated Linux environments that share the host's kernel. The SSH server on port 2222 logs in to Kishi itself with the default Vagrant credentials, and every container has an administrator account that the page says is not part of the game and should only be used for setting up or debugging. Change those passwords if you connect the VM to a public network.

### Run it safely

- **Isolate the network.** These images are intentionally vulnerable. Use a host-only or internal network in your hypervisor so the machine is not reachable from the internet or your home network.
- **Snapshot before you start.** A snapshot lets you roll back after you break something.
- **Use a disposable environment.** A spare virtual machine host, not the laptop that holds your real data.
- **Change default credentials** if you ever connect a lab image to a shared network.
- **Keep notes.** Story-driven games reward writing down every credential, host and clue as you find it.

### Where this fits

Kishi suits players comfortable with Linux administration, networking and web security who want a scenario with several hosts.

</section>

<!-- study-guide:end -->
