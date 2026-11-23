---
title: "Bandit Level 2"
description: "Bandit Level 2 — read a file literally named \"-\" and learn why commands treat a leading dash as an option."
permalink: /docs/wargames/bandit/bandit2/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit2.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 2 — read a file literally named \"-\" and learn why commands treat a leading dash as an option."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 2
sidebar_label: "Level 2"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
The password for the next level is stored in a file called **-** located in the home directory

Commands you may need to solve this level
-----------------------------------------
[ls](https://manpages.ubuntu.com/manpages/noble/man1/ls.1.html) , [cd](https://manpages.ubuntu.com/manpages/noble/man1/cd.1posix.html) , [cat](https://manpages.ubuntu.com/manpages/noble/man1/cat.1.html) , [file](https://manpages.ubuntu.com/manpages/noble/man1/file.1.html) , [du](https://manpages.ubuntu.com/manpages/noble/man1/du.1.html) , [find](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html)

Helpful Reading Material
------------------------
- [Google Search for "dashed filename"][]
- [Advanced Bash-scripting Guide - Chapter 3 - Special Characters][]

[Google Search for "dashed filename"]: https://www.google.com/search?q=dashed+filename
[Advanced Bash-scripting Guide - Chapter 3 - Special Characters]: https://linux.die.net/abs-guide/special-chars.html

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `bandit1`, find the password for `bandit2`.
</div>

### What this level teaches

Why some filenames break commands, and how to talk to a command about a file that looks like an option.

### Key ideas

- **Options start with a dash.** `cat -n file` means "number the lines". A bare `-` is conventionally "standard input", so a command that receives only `-` does not see a file at all.
- **The shell passes arguments through unchanged.** It is the program, not the shell, that decides `-` is special.
- **Two standard remedies exist:** make the argument unmistakably a path, or tell the program that options have ended. Both are described in the man pages of nearly every command.

### How to approach it

1. Run `ls` and notice the odd filename. Try `cat` on it and observe what happens; failing on purpose is a good way to learn.
2. Think about how to write a path that does not begin with a dash. The current directory has a short name you already know.
3. Search `man cat` or `man bash` for the "end of options" convention, which is useful for every command you will ever use.

### Why it matters

Attackers deliberately create files whose names look like command-line flags, which can trick scripts that run `rm *` or `tar *` into executing options. Knowing the mechanism is how you defend against it.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit1/">Level 1</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit3/">Level 3</a></nav>

</section>

<!-- study-guide:end -->
