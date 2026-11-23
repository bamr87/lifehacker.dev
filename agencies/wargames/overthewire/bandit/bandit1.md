---
title: "Bandit Level 1"
description: "Bandit Level 1 — find and read a file named readme in your home directory using ls and cat."
permalink: /docs/wargames/bandit/bandit1/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit1.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 1 — find and read a file named readme in your home directory using ls and cat."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 1
sidebar_label: "Level 1"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in a file called **readme** located in the home directory. Use this password to log into bandit1 using SSH. Whenever you find a password for a level, use SSH (on port 2220) to log into that level and continue the game.

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html)

**TIP:** Create a file for notes and passwords on your local machine!

Passwords for levels are *not* saved automatically. If you do not save them yourself, you will need to start over from bandit0.

Passwords also occasionally change. It is recommended to take notes on how to solve each challenge. As levels get more challenging, detailed notes are useful to return to where you left off, reference for later problems, or help others after you've completed the challenge.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit0`, find the password for `bandit1`.
</div>

### What this level teaches

Orientation in a Unix filesystem and your first real data-gathering commands. A password is waiting in an ordinary file; the skill is knowing where you are and how to look inside a file.

### Key ideas

- **Home directory** — the folder you land in after logging in, shorthand `~`. `pwd` prints the current directory.
- **`ls`** lists a directory's contents. Options such as `-l` (long format) and `-a` (include hidden entries) change what you see.
- **`cat`** prints a file's contents to the terminal.
- **Everything is a file** — on Unix, configuration, devices and passwords are all just files with permissions.

### How to approach it

1. Look around before acting: `pwd`, then `ls`.
2. Print the file that the Level Goal names.
3. Copy the result into your notes file. The password is plain text, and the next level's login (`ssh bandit1@...`) needs it.

### Why it matters

"Where am I, what is here, what does it say?" is the loop you will run thousands of times, on every system you ever investigate.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit0/">Level 0</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit2/">Level 2</a></nav>

</section>

<!-- study-guide:end -->
