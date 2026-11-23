---
title: Wargames
description: "A map of all OverTheWire wargames — what each teaches, how hard it is, how to connect, the best order to play them in, and the ground rules."
excerpt: "A map of all OverTheWire wargames — what each teaches, how hard it is, how to connect, the best order to play them in, and the ground rules."
permalink: /docs/wargames/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Wargames
========

The wargames offered by the OverTheWire community can help you to learn and practice security concepts in the form of fun-filled games.<br/> To find out more about a certain wargame, just visit its page linked from the menu on the left.

If you have a problem, a question or a suggestion, you can [join us via chat][contactus].

Suggested order to play the games in
------------------------------------

1. Bandit - Unix/Linux basics
2. Pick one:
   * Natas  - web security
   * Krypton - cryptography
   * Leviathan  - reverse engineering
3. Narnia - Start into binary exploitation (and reverse engineering)
4. Behemoth - binary exploitation (and reverse engineering)
5. Utumno - binary exploitation (and reverse engineering)
6. Maze - binary exploitation (and reverse engineering)
7. ...

Each shell game has its own SSH port
------------------------------------

Information about how to connect to each game using SSH, is provided in the top left corner of the page. Keep in mind that every game uses a different SSH port.

[contactus]: https://overthewire.org/information/chat.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is a map of the whole collection. It explains how a wargame works, compares the games, recommends an order and sets out the ground rules. It is spoiler-free: nothing here gives away a password or a finished solution.

### How a wargame works

A wargame is a sequence of levels. Each level contains a small security problem; when you solve it you receive the key to the next level, usually a password. Most OverTheWire games are played over SSH: you connect to a game server on its own port, log in as the account for the current level, and use ordinary Unix tools to find the next password. Natas is the exception: its levels are websites you visit in a browser. A few older games are distributed as virtual machines you run yourself.

The point is not the password. It is the skill you build in finding it: reading manuals, forming hypotheses, testing them, and keeping notes.

### The games at a glance

| Game | What it teaches | Levels | How to connect | Difficulty and status |
|------|-----------------|--------|----------------|-----------------------|
| [Bandit](bandit/) | Linux command line, SSH, text tools, git | 0–33 | SSH, port 2220 | beginner |
| [Natas](natas/) | server-side web security | 0–34 | web browser | beginner to intermediate |
| [Krypton](krypton/) | classical and introductory cryptography | 0–6 | SSH, port 2231 | beginner to intermediate |
| [Leviathan](leviathan/) | first steps in reverse engineering | 0–7 | SSH, port 2223 | 1/10 |
| [Narnia](narnia/) | basic binary exploitation, with source | 0–9 | SSH, port 2226 | 2/10 |
| [Behemoth](behemoth/) | binary exploitation without source | 0–8 | SSH, port 2221 | 3/10 |
| [Utumno](utumno/) | harder binary exploitation | 0–8 | SSH, port 2227 | 4/10 |
| [Maze](maze/) | tricky exploitation and reverse engineering | 0–9 | SSH, port 2225 | 5/10 |
| [Manpage](manpage/) | finding bugs by reading manuals | 0–7 | SSH, port 2224 | not rated |
| [Vortex](vortex/) | mixed advanced topics | 0–26 | SSH, port 2228 | advanced; no new levels planned |
| [Drifter](drifter/) | Vortex-style advanced topics | 0–15 | SSH, port 2230 | advanced |
| [FormulaOne](formulaone/) | exploitation, rescued from intruded.net | 0–6 | SSH, port 2232 | advanced |
| [Semtex](semtex/) | network programming and reversing | 0–12 | SSH, port 2229 | offline |
| [Blacksun](blacksun/) | exploiting hardened hosts | 0–4 | network services | currently down |
| [Abraxas](abraxas/), [HES2010](hes2010/), [Kishi](kishi/), [Monxla](monxla/) | story-driven conference games | — | download a virtual machine | released; play locally |

### Recommended order

1. **Bandit** first. It teaches the commands and habits every other game assumes.
2. **Then one of Natas, Krypton or Leviathan.** Pick by interest: web security, cryptography or reverse engineering. Eventually do all three.
3. **Narnia** to start binary exploitation. You are given the source code, which keeps the first steps manageable.
4. **Behemoth**, which no longer gives you the source.
5. **Utumno**, then **Maze**.
6. **Vortex, Drifter, FormulaOne and Manpage** as longer, mixed-difficulty extensions.
7. **The conference games and the offline games** for story-driven variety once you are experienced.

### Prerequisites by theme

- **Command-line fluency** — Bandit; needed for everything.
- **Web basics (HTTP, HTML, cookies)** — useful before Natas.
- **Basic C, memory and assembly** — essential from Narnia onward. Practise reading C and a debugger before you start.
- **Maths and patience** — Krypton and the cryptography-flavoured levels in Vortex and Semtex.

### Setting up your workspace

- A terminal with an SSH client (Linux, macOS and recent Windows all include one).
- A text file or notebook where you record each password and, more importantly, how you solved the level.
- For binary games, a local Linux virtual machine so you can test tools such as `gdb`, `gcc` and `pwntools` freely.
- `man` pages open in a second window.

### Ground rules

- **Only attack the wargame servers,** and only the accounts and services the game provides. Never apply these techniques to systems you do not own or have written permission to test.
- **Do not disrupt other players.** Avoid denial-of-service, do not fill the disk, and clean up after yourself in `/tmp`.
- **Do not spoil the game.** Do not publish passwords or step-by-step solutions. Write about the *concepts* instead.
- **Ask for help the right way.** Say what you tried and what you saw. The OverTheWire community chat is linked at the top of this page.

### How to read the study guides on this site

Every page in this collection has the original upstream text first, then a **Study guide** section added by this site. The guide explains the concepts, suggests an approach without giving away the answer, and says why the skill matters in real work. The first line of most guides is a **Level map** that tells you which account you are logged in as and which password you are looking for, because the numbering differs between games.

</section>

<!-- study-guide:end -->
