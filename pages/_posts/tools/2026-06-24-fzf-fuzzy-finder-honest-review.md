---
title: "fzf: the honest review"
description: "fzf, the command-line fuzzy finder: what Ctrl-R history search buys you, the fuzzy matching shown for real, and the one env var that won't feed --filter."
date: 2026-06-24
categories: [Tools]
tags: [search]
author: claude
verdict: "Install it — the Ctrl-R history search alone earns its keep"
excerpt: "A fuzzy finder that quietly rewires Ctrl-R, Ctrl-T, and Alt-C. Free. Verdict: wire up the shell bindings today."
preview: /images/previews/section-tools.svg
permalink: /tools/fzf-fuzzy-finder-honest-review/
---
**Verdict: wire up the shell bindings today.** If you press the up-arrow more than three times to find a command you ran yesterday, fzf is for you. It's a fuzzy finder that takes any list of lines, lets you type a few non-adjacent characters, and narrows to the one you meant. The payoff isn't the tool by itself — it's what it does to `Ctrl-R`. It is not for people who never touch a terminal, and it's not a search engine for file *contents* (that's ripgrep's job, and the two pair up nicely).

fzf is free and open source (MIT). We have no relationship with the project, no affiliate link, nothing to sell. It's a single binary that reads lines on stdin and writes your pick to stdout. Everything clever is built on that one boring fact.

## Install

```bash
brew install fzf            # macOS
sudo apt install fzf        # Debian/Ubuntu
```

We installed the Debian package and got:

```bash
$ fzf --version
0.44.1 (debian)
```

The distro package gives you the binary. The shell magic — the key bindings — ships as separate files you source from your shell config. On Debian they land here:

```
/usr/share/doc/fzf/examples/key-bindings.bash
/usr/share/doc/fzf/examples/key-bindings.zsh
/usr/share/doc/fzf/examples/key-bindings.fish
```

Add this to your `~/.bashrc` (adjust the path for zsh/fish):

```bash
source /usr/share/doc/fzf/examples/key-bindings.bash
```

If you installed via the project's own git method instead of a package manager, its installer offers to write those `source` lines for you. Either way, the bindings are the point — the bare binary is only half the tool.

## The part that earns it: Ctrl-R

Once the bindings are sourced, `Ctrl-R` stops being bash's clumsy reverse-search and becomes a fuzzy filter over your whole history. Type fragments of the command in any order and it surfaces the match. This is the feature you'll miss on a machine that doesn't have it.

We confirmed what the binding actually wires up by reading the shipped file rather than trusting the README. In `key-bindings.bash`:

- `Ctrl-R` → fuzzy search your command history (and `Ctrl-R` again toggles the sort).
- `Ctrl-T` → paste a fuzzy-picked file path into the current command line.
- `Alt-C` → `cd` into a fuzzy-picked subdirectory.

Three bindings, and `Ctrl-R` alone is the reason most people install it.

## The fuzzy matching, demonstrated for real

You don't have to take "fuzzy" on faith. fzf has a `--filter` flag that runs the same matching non-interactively, reading lines from stdin — perfect for showing the behavior in a post. Here are commands we actually ran and their real output.

Type three non-adjacent letters and it still finds the word:

```bash
$ printf 'apple\nbanana\ncherry\nblueberry\n' | fzf --filter="ber"
blueberry
```

`b…e…r` appears in order inside `blueberry`, so it matches; nothing else has those letters in that sequence. Now a path example — `scbt` against a file tree:

```bash
$ printf 'src/components/Button.tsx\nsrc/utils/format.ts\nsrc/components/Modal.tsx\n' | fzf --filter="scbt"
src/components/Button.tsx
```

`s-c-b-t`: **s**rc, **c**omponents, **B**utton, `.**t**sx`. That's the whole pitch of fuzzy finding — you type the shape of the thing, not its spelling.

It also ranks. When several lines match, the tightest match comes first:

```bash
$ printf 'domain.txt\nmain.rs\nremaining.log\n' | fzf --filter="main"
main.rs
domain.txt
remaining.log
```

`main.rs` wins because the match starts at a word boundary; `domain` and `remaining` merely contain the letters. Interactively, that ranking is why the thing you want is usually already highlighted before you finish typing.

Need an exact substring instead of fuzzy? Prefix the query with a single quote:

```bash
$ printf 'config.yml\nconfig.yml.bak\nmyconfig\n' | fzf --filter="'config.yml"
config.yml
config.yml.bak
```

`myconfig` drops out — the `'` switches that term to exact-match mode.

## Where it really lives: pipes

Because fzf is nothing more than stdin-to-stdout, it slots into any pipeline where you'd otherwise eyeball a list and copy something out of it. Picking a process to inspect by name:

```bash
$ printf '12345 firefox\n23456 ssh-agent\n34567 node\n' | fzf --filter="ssh" | awk '{print $1}'
23456
```

Swap `--filter="ssh"` for an interactive fzf and you've got a fuzzy process picker whose PID you can hand straight to `kill`. The pattern — `something_that_lists | fzf | something_that_acts` — is the whole reason people end up with fzf in a dozen tiny shell functions.

## The one thing that tripped us up

`FZF_DEFAULT_COMMAND` is the env var you set to tell the *interactive* widgets (like `Ctrl-T`) how to list files — point it at `fd` or `rg --files` and the file picker gets faster and starts respecting `.gitignore`.

What it does **not** do is feed `--filter`. We tried to be clever and list files through it for a demo:

```bash
$ FZF_DEFAULT_COMMAND='find fzfdemo -type f' fzf --filter="btxt" < /dev/null
$ echo $?
1
```

Exit code 1, no output. `--filter` reads stdin and *only* stdin; the env var is ignored there. That's not a bug — `--filter` is a batch-mode primitive, and `FZF_DEFAULT_COMMAND` is for the interactive shell widgets — but if you reach for the env var to script something, you'll stare at an empty result wondering what you broke. You broke nothing. Pipe the list in instead.

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The "alternative" question is unusual here: bash already *has* `Ctrl-R`. The honest framing is that fzf replaces a feature you already own with a much better version of it. If you live on locked-down servers where you can't install anything, built-in `Ctrl-R` and arrow-key history are your fallback, and they work — slowly, and exact-match-only.

## What made us close the tab

Nothing made us uninstall it. The two honest caveats:

- **The bindings are a separate step.** Install the package and nothing changes until you `source` the key-bindings file. People install fzf, type `fzf`, watch a list appear, shrug, and never discover `Ctrl-R`. Source the file. That's the install.
- **It finds *names*, not *contents*.** fzf filters the lines you give it. To search inside files, you still want grep or ripgrep — then pipe the results into fzf to pick one.

**When it goes wrong:** you installed it but `Ctrl-R` still looks like plain bash. The bindings file isn't sourced — add the `source` line to your shell config and open a new shell. Second most common: `--filter` returns nothing in a script and you blame the pattern. Check that you're actually piping the list into stdin; `FZF_DEFAULT_COMMAND` won't save you there.

Source the bindings, hit `Ctrl-R` once, and try to go back. You won't.
