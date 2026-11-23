---
title: Bandit
description: "Bandit is the beginner Linux and SSH wargame — 34 short levels that teach the command-line skills every other OverTheWire game assumes."
permalink: /wargames/bandit/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/index.md
source_name: overthewire
license: MIT
author: amr
excerpt: "Bandit is the beginner Linux and SSH wargame — 34 short levels that teach the command-line skills every other OverTheWire game assumes."
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

Bandit
======

The Bandit wargame is aimed at absolute beginners. It will teach the basics needed to be able to play other wargames. **If you notice something essential is missing or have ideas for new levels, please let us know!**

Note for beginners
------------------

This game, like most other games, is organised in levels. You start at Level 0 and try to "beat" or "finish" it. Finishing a level results in information on how to start the next level. The pages on this website for "Level <X\>" contain information on how to start level X from the previous level. E.g. The page for [Level 1][] has information on how to gain access from [Level 0][] to [Level 1][]. All levels in this game have a page on this website, and they are all linked to from the sidemenu on the left of this page.

You will encounter many situations in which you have no idea what you are supposed to do. **Don't panic! Don't give up!** The purpose of this game is for you to learn the basics. Part of learning the basics, is reading a lot of new information. If you've never used the command line before, a good first read is this [introduction to user commands][].

There are several things you can try when you are unsure how to continue:

-   First, if you know a command, but don't know how to use it, try the **manual** ([man page][]) by entering **man <command\>**. For example, **man ls** to learn about the "ls" command. The "man" command also has a manual, try it! When using **man**, press `q` to quit (you can also use `/` and `n` and `N` to search).
-   Second, if there is no man page, the command might be a **shell built-in**. In that case use the "**help <X\>**" command. E.g. help cd
-   Also, your favorite **search-engine** is your friend. Learn how to use it! I recommend [Google][].
-   Lastly, if you are still stuck, you can [join us via chat][]

You're ready to start! Begin with [Level 0][], linked at the left of this page. Good luck!

**Note for VMs:** You may fail to connect to overthewire.org via SSH with a "*broken pipe error*” when the network adapter for the VM is configured to use NAT mode. Adding the setting **`IPQoS throughput`** to `/etc/ssh/ssh_config` should resolve the issue. If this does not solve your issue, the only option then is to change the adapter to Bridged mode. 

  [Level 1]: {{ '/wargames/bandit/bandit1/' | relative_url }}
  [Level 0]: {{ '/wargames/bandit/bandit0/' | relative_url }}
  [introduction to user commands]: https://manpages.ubuntu.com/manpages/noble/man1/intro.1.html
  [man page]: https://en.wikipedia.org/wiki/Man_page
  [Google]: https://www.google.com
  [join us via chat]: https://overthewire.org/information/chat.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it explains what each stretch of Bandit teaches and how to get unstuck, but it never lists passwords or finished solutions. The struggle is where the learning happens.

### What Bandit teaches

Bandit is a guided tour of the Unix command line. You begin with a single SSH login and finish by chaining small tools, scripting, scheduling jobs, abusing misconfigured permissions and escaping restricted shells. Nothing needs programming experience; every level can be solved with standard tools that ship on any Linux system.

### How the levels are numbered

Each level page describes how to get **to** that level from the one before it. The page titled Level 1 is therefore done while logged in as `bandit0`, and its result is the password for `bandit1`. The study guide on each page repeats this as a "Level map" line so you never have to count.

### The learning path

| Levels | Theme | Core skills |
|--------|-------|-------------|
| 0–3 | First steps | SSH, `ls`, `cat`, files with awkward names |
| 4–7 | Finding things | hidden files, `file`, `find`, permissions and ownership |
| 8–12 | Text and encodings | `grep`, `sort`, `uniq`, `strings`, Base64, ROT13, compression |
| 13–17 | Keys and networks | SSH keys, ports, `nc`, TLS with `openssl`, port scanning |
| 18–21 | Identity and privilege | `diff`, remote commands, setuid binaries, job control |
| 22–25 | Automation | cron, shell scripting, brute force |
| 26–27 | Escaping shells | restricted login shells, `more`/`vi` escape hatches |
| 28–32 | Git | clone, history, branches, tags, push hooks |
| 33 | Last escape | breaking out of a hostile shell |

### Tools worth knowing before you start

- `man` — the built-in manual. Press `/` to search and `q` to quit. Reading man pages is the single most useful habit Bandit builds.
- `ssh`, `scp` — remote shell and file copy.
- `grep`, `find`, `sort`, `uniq`, `tr`, `diff` — the text-processing core.
- `nc` (netcat), `openssl`, `nmap` — network clients and scanners.
- `git` — needed on your own machine for Levels 28–32.

### Study habits that pay off

- Keep a notes file on your own machine: password, command that worked, and one sentence on *why*. Passwords are not saved for you and occasionally change.
- Predict the output of a command before you run it. Surprises are where the learning is.
- When stuck, shrink the problem: run each command in a pipeline separately and look at what each stage produces.
- Work in a private directory under `/tmp` made with `mktemp -d` whenever you need to create files; you usually cannot write to your home directory.
- Be a good neighbour. Other players share the server, so clean up temporary files and never hunt for other people's work.

### After Bandit

The suggested order on the [games index](../) is Bandit first, then any of Natas (web), Krypton (cryptography) or Leviathan (reverse engineering), then the binary-exploitation games Narnia, Behemoth and onward.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="bandit0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
