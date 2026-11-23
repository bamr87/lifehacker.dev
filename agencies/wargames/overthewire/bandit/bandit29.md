---
title: "Bandit Level 29"
description: "Bandit Level 29 — find a secret that was removed from the current files but is still preserved in Git history."
permalink: /docs/wargames/bandit/bandit29/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit29.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 29 — find a secret that was removed from the current files but is still preserved in Git history."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 29
sidebar_label: "Level 29"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a git repository at `ssh://bandit28-git@bandit.labs.overthewire.org/home/bandit28-git/repo` via the port `2220`. The password for the user `bandit28-git` is the same as for the user `bandit28`.

From your local machine (not the OverTheWire machine!), clone the repository and find the password for the next level. This needs git installed locally on your machine.


Commands you may need to solve this level
-----------------------------------------
git

Helpful Reading Material
------------------------
- [Installing Git][]
- [Git from the Bottom Up][]

[Installing Git]: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
[Git from the Bottom Up]: https://jwiegley.github.io/git-from-the-bottom-up/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** using the password for `bandit28`, find the password for `bandit29`.
</div>

### What this level teaches

Deleting something from the latest version of a repository does not delete it from history.

### Key ideas

- **Commits are snapshots.** Each commit records the full state of the project and a message describing the change.
- **`git log`** lists commits; `git show` and `git diff` display what a commit changed.
- **Leaked secrets persist.** Credentials committed once remain recoverable from earlier commits even after a "fix" commit.

### How to approach it

1. Clone the repository and read the current files.
2. Read the commit log, paying attention to commit messages that suggest something was fixed or removed.
3. Inspect those earlier commits to see exactly what they changed.

### Why it matters

Committing API keys and passwords is one of the most common real-world leaks. If it happens, rotate the secret; rewriting history is not enough.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit28/">Level 28</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit30/">Level 30</a></nav>

</section>

<!-- study-guide:end -->
