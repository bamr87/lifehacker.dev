---
title: "Bandit Level 5"
description: "Bandit Level 5 — identify the one human-readable file among many using the file command."
permalink: /docs/wargames/bandit/bandit5/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit5.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 5 — identify the one human-readable file among many using the file command."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 5
sidebar_label: "Level 5"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in the only human-readable file in the **inhere** directory. Tip: if your terminal is messed up, try the "reset" command.

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html)

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit4`, find the password for `bandit5`.
</div>

### What this level teaches

A filename or extension tells you nothing reliable about contents. The `file` command inspects the data itself.

### Key ideas

- **Magic numbers.** Many file formats begin with signature bytes. `file` reads them and reports a type such as ASCII text, data or executable.
- **Why printing binary files hurts.** Sending arbitrary bytes to a terminal can send control codes that garble your display. If that happens, the `reset` command restores it.
- **Filenames can still be awkward.** The files in this directory begin with a character that already caused trouble in an earlier level.

### How to approach it

1. List the directory, then run `file` on every candidate at once using a wildcard. Remember how Level 2 told you to write the paths.
2. Only `cat` the file that `file` identifies as text.

### Why it matters

Forensics, malware triage and upload filters all rely on content-based identification rather than trusting names, a theme that returns strongly in the web-security game Natas.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit4/">Level 4</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit6/">Level 6</a></nav>

</section>

<!-- study-guide:end -->
