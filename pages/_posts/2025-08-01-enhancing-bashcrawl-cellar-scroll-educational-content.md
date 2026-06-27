---
title: "Field Notes: rewriting a Bashcrawl scroll, and the ls -F lesson that survived the prose"
description: "Rewriting a Bashcrawl tutorial taught me ls -F classifiers, and why alias ls='ls -F' quietly does nothing in a script — the part the original scroll skipped."
date: 2025-08-01
categories: [Field Notes]
tags: [bash, ls, aliases, bashcrawl, terminal]
author: amr
excerpt: "I set out to make a teaching scroll prettier and ended up debugging why my own alias didn't fire. The classifiers are the lesson; the alias is the trap."
---

[Bashcrawl](https://gitlab.com/slackermedia/bashcrawl) is a dungeon crawler where the dungeon is a directory tree and the only weapon is `cd`. One of its early scrolls teaches `ls -F` and a shell alias. I picked it up to make it less terse — more tables, more "here's why this matters" — and within ten minutes I was no longer editing prose. I was staring at a terminal asking why my alias did nothing.

That detour is the actual content. The tutorial taught `alias ls='ls -F'` as if it always sticks. It doesn't. So here's the rewrite I'd ship, with the part where it broke left in.

## What `ls -F` actually buys you

`ls` lists names. `ls -F` lists names with a one-character classifier glued to the end, so you can tell what each thing *is* without running anything. Same listing, two readings:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir armoury
printf '#!/bin/sh\necho hi\n' > treasure && chmod +x treasure
ln -s armoury portal
mkfifo message_pipe
printf 'you found the treasure\n' > scroll

echo '$ ls'
ls
echo
echo '$ ls -F'
ls -F
```

Real output from that block:

```console
$ ls
armoury
message_pipe
portal
scroll
treasure

$ ls -F
armoury/
message_pipe|
portal@
scroll
treasure*
```

The suffix is the whole point. Here's the legend, which is the one table worth keeping from the "make it comprehensive" pass:

| Suffix | What it means | In the dungeon |
|--------|---------------|----------------|
| `/` | directory | a room you can `cd` into |
| `*` | executable | a thing you can run |
| `@` | symbolic link | a portal to somewhere else |
| `\|` | named pipe (FIFO) | a one-way message channel |
| `=` | socket | a live connection point |
| (none) | regular file | a scroll, a note, plain data |

You'll know it worked when a plain `ls` and an `ls -F` of the same folder no longer look identical: the `-F` version sprouts those trailing symbols.

## The part where it broke: the alias that fired blanks

The scroll's payoff is to make it permanent:

```bash
alias ls='ls -F'
```

Type that in your terminal and it works. Put the same line in a script — which is exactly what you do when you're "making it permanent" by writing it into a setup file you test with `bash setup.sh` — and it evaporates. No error. The marks never show up. I burned real minutes assuming I'd fat-fingered the alias.

Here is the failure, reproduced honestly:

```bash
# lh:run
printf "alias ls='ls -F'\nls -d .\n" | bash
echo "exit: $?"
```

Output — note there is no `/` on the dot, and no complaint:

```console
.
exit: 0
```

The alias was defined and then completely ignored. The reason is a default I had forgotten: **bash does not expand aliases in non-interactive shells.** Your interactive terminal turns alias expansion on for you. A script does not. So the line that "works when I type it" is silently inert the moment it runs anywhere else.

There's a second, sharper edge once you switch it on. Aliases only take effect on lines bash reads *after* the alias definition — so a single `bash -c "alias ...; use-it"` still fails, because the whole string is parsed in one go. You need the enabling line and the usage on separate lines:

```bash
# lh:run
printf "shopt -s expand_aliases\nalias greet='echo hello from alias'\ngreet\n" | bash
```

```console
hello from alias
```

That works. Drop the `shopt` line and it goes back to `greet: command not found`. I checked both ways.

So the honest version of the scroll's advice is: `alias ls='ls -F'` belongs in your **interactive** shell config (`~/.bashrc`, `~/.zshrc`), where alias expansion is already on and the file is sourced fresh each session. It does **not** belong in a script you expect to behave the same way — there, call `ls -F` directly or turn expansion on by hand.

## The other thing the tutorial got away with: color

The original wanted to teach `alias ls='ls -F --color=auto'`. That line is a GNU-ism. On a Mac, the stock `ls` is the BSD one, and it has no idea what `--color=auto` is:

```console
$ ls --color=auto
ls: unrecognized option `--color=auto'
```

(I can quote that exactly because that's the error this machine's BSD `ls` gives — it's the same one that tells you the flavor: `ls --version` answers `unrecognized option '--version'` on BSD, and prints a version banner on GNU. That's the cheapest way to know which `ls` you're talking to.)

The portable move is to keep `-F` for classifiers and add color the way your `ls` actually spells it:

```bash
# GNU coreutils (most Linux):
alias ls='ls -F --color=auto'

# BSD ls (macOS default):
alias ls='ls -FG'
```

Same outcome, two dialects. The tutorial assumed everyone was on GNU. Most "paste this into your shell config and move on" snippets do.

## What I actually kept from the rewrite

I went in to add structure and came out having deleted most of it. The legend table stayed because it earns its space. The "real-world applications" bullet list and the game-achievement framing did not — they were words about learning, not the thing being learned.

The keepers, in order of how much time they would have saved me:

- `ls -F` classifies entries by a trailing symbol; the `/ * @ | =` legend is the whole skill.
- `alias ls='ls -F'` is an *interactive*-shell trick. In a script, alias expansion is off unless you `shopt -s expand_aliases`, and even then it only applies to lines read after the definition.
- Color is `--color=auto` on GNU and `-G` on BSD/macOS. Pick the one your `ls` understands or the alias errors out.
- `ls --version` failing is itself the tell that you're on BSD `ls`.

The scroll taught one flag and one alias. The honest version teaches one flag, one alias, and the three places that alias quietly doesn't do what the line says. The marks on the screen were never the hard part. Knowing when they won't show up was.
