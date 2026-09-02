---
title: "tealdeer: the honest review"
description: "The fast tldr client: a 1164-line man page becomes five copy-paste commands, cached over the network — and exit 0 even when the download is garbage."
date: 2026-09-02
categories: [Tools]
tags: [productivity, system]
author: cass
verdict: "Install it (the tealdeer one, not the transitional tldr) — but turn OFF auto_update, because it fetches community-written commands over the network and returns exit 0 even when the download fails"
excerpt: "The tldr client that hands you five crowdsourced commands instead of the man page. Fast, offline once cached, genuinely useful — and a supply chain wearing a friendly cyan sweater. Verdict: keep it, pin the client, kill auto-update."
preview: /images/previews/tealdeer-the-honest-review.svg
permalink: /tools/tealdeer-honest-review/
---
**Verdict: install it, run `apt install tealdeer` (not `tldr` — I'll get to that), put `auto_update = false` in the config before you do anything else, and update the cache by hand while watching the exit code. tealdeer is genuinely good and I use it every day. It is also a program whose entire job is to download commands written by strangers and render them in a friendly color so you'll paste them into a shell.** That is not a knock. That is the threat model, and the tool ships without one.

tldr is the project that replaces the man page with the part of the man page you actually wanted: a handful of worked examples. `man tar` is 1164 lines on my box — I counted, `man tar | wc -l` — and you opened it to remember which letters mean "extract this thing." tealdeer answers that question in five lines and half a second. I have no relationship with tealdeer or the tldr-pages project. Both are free, MIT-licensed, and open source; nobody paid me. I don't trust free things either, which is exactly why this review exists.

## The convenience: you don't read the manual anymore

Here is what earns the install. Once the cache is warm, tealdeer renders a page like this — real captured output, `tldr tar`, from the cache on my machine:

```console
$ tldr tar

  Archiving utility.
  Often combined with a compression method, such as gzip or bzip2.
  More information: <https://www.gnu.org/software/tar>.

  [c]reate an archive and write it to a [f]ile:

      tar cf path/to/target.tar path/to/file1 path/to/file2 ...

  [c]reate a g[z]ipped archive and write it to a [f]ile:

      tar czf path/to/target.tar.gz path/to/file1 path/to/file2 ...

  E[x]tract a (possibly compressed) archive [f]ile into the current directory [v]erbosely:

      tar xvf path/to/source.tar[.gz|.bz2|.xz]
```

Fast, offline once cached, no telemetry, written in Rust, and the bracket notation (`[c]reate`, `[f]ile`) tells you which letter does what — the one thing the man page makes you hunt for. If the review ended here it would be a rave. It doesn't, because a convenience feature is an attack surface with better marketing, and this one has three.

## Attack surface #1: you don't know which program answered

Type `tldr` and something responds. What? On Ubuntu, `apt install tldr` does not install tealdeer. It installs a *transitional package*. Real captured output:

```console
$ apt-cache show tldr | grep -iE '^(Depends|Description)'
Depends: tldr-hs
Description-en: transitional package
```

`tldr` the package is a stub that pulls in `tldr-hs` — the *Haskell* client — a different program by a different author with different network behavior. And it is not the only impostor. Ask apt what "tldr" means and you get a lineup:

```console
$ apt-cache search tldr
libghc-tldr-dev - Haskell tldr client
tealdeer - simplified, example based and community-driven man pages
tldr - transitional package
tldr-hs - Haskell tldr client
tldr-py - Python client for tldr: simplified and community-driven man pages
```

Haskell client, Python client, a transitional stub, and the Rust one I actually wanted. There's an npm `tldr` at version 3.5.0 too. `tldr` is not a program. It's a spec — the tldr-pages markdown format — with a half-dozen client implementations, all answering to the same command name. So which one is on your PATH? The tealdeer binary is *also* called `tldr`, and it tells on itself:

```console
$ tldr --version
tealdeer 1.6.1
```

The package is `tealdeer`. The binary is `tldr`. The version string says `tealdeer`. Three names for one program, and a second program (`tldr-hs`) waiting to take the same name if you install the wrong package. **SEVERITY: your muscle memory. ATTACK VECTOR: a command name owned by five packages and a transitional stub that redirects to none of them. BLAST RADIUS: you audited the network behavior of tealdeer and shipped the Haskell client.** Walk it back: this won't get you breached on its own. But you cannot threat-model a binary you can't name, and step one of trusting a tool is knowing which tool you're running.

## Attack surface #2: it downloads commands from the internet — and lies about failing

tealdeer ships empty. First run, no cache, real captured output:

```console
$ tldr tar
Page cache not found. Please run `tldr --update` to download the cache.
```

That exits `1` — correct, honest, a missing cache is a failure. So you run `tldr --update`, and here is where I stop smiling. That command reaches out over the network, downloads a ZIP of roughly ten thousand pages, and extracts them into your cache directory. Those pages then become the commands tealdeer renders in friendly cyan for you to paste. It is a remote code *suggestion* channel, and the channel's integrity is one HTTPS fetch you never see.

I ran this review on a locked-down box where a proxy sits between me and the internet. Watch what `tldr --update` did:

```console
$ tldr --update
Could not update cache

Caused by:
    0: Could not decompress downloaded ZIP archive
    1: invalid Zip archive: Could not find central directory end
$ echo "exit=$?"
exit=0
```

Read the last line twice. The download was intercepted and replaced with something that was not a ZIP — in my case 673 bytes of proxy HTML where ten thousand pages should have been — tealdeer noticed, printed "Could not update cache," **and returned exit code 0.** A failed integrity check on a channel that populates the commands you're about to run, reported as success. If you script `tldr --update` in your dotfiles or CI and gate on its exit code, it will tell you everything's fine while your cache is empty, stale, or whatever the network handed it.

Now recall the config file's cheerful suggestion from that first-run message:

```
  [updates]
  auto_update = true
```

The docs, and half the blog posts, tell you to turn that on so you never think about the cache again. That is the pitch. Here's the same config with a blocked download and `auto_update = true` — I set it and ran `tldr tar`:

```console
$ tldr tar

Caused by:
    0: Could not decompress downloaded ZIP archive
    1: invalid Zip archive: Could not find central directory end
$ echo "exit=$?"
exit=0
```

"Never think about the cache again" turns out to mean "never *find out* the cache silently failed to update." Every invocation now quietly reaches for the network, and every failure is exit 0. To be scrupulously clear: on a normal, un-intercepted network, `tldr --update` works fine and pulls the real ten-thousand-page cache — the pages you saw rendered above are real tldr-format pages I placed in the cache directory by hand *because* my proxy ate the download. The renderer output is genuine tealdeer. The silent exit-0-on-a-failed-fetch is genuine too, and it's the part I can't unsee. **SEVERITY: a coffee-shop router. ATTACK VECTOR: a ZIP fetched over the network and extracted into the source of your command suggestions, with integrity failures reported as success. BLAST RADIUS: realistically, a stale cheat sheet. Theoretically, a cache full of whatever your network wanted you to paste.**

## Attack surface #3: a suggestion isn't a contract

Even with a perfect, freshly-downloaded cache, remember what a tldr page *is*: five lines of community-contributed markdown from a public GitHub repo anyone can open a pull request against. The pages are good — genuinely, the tldr-pages project is well-maintained and reviewed. But the tool renders the safe examples and the dangerous ones in the exact same friendly cyan, with no notion that `tar xvf` over an existing tree, or the `rm` and `dd` examples on other pages, deserve a different color than "create an archive." tealdeer will happily render a page that doesn't exist as a clean "not found," too:

```console
$ tldr thistooldoesnotexist
Page `thistooldoesnotexist` not found in cache.
Try updating with `tldr --update`, or submit a pull request to:
https://github.com/tldr-pages/tldr
```

That one exits `1`, which is more honesty than the update path managed. The point stands: tldr is a memory jog, not a manual. It shows you *a* way, distilled by strangers, with the flags' actual meanings living in the 1164 lines you skipped.

## The three mitigations that actually matter

Paranoia without a payload is just anxiety. Here is what I configured and tested, ranked.

**1. Install the client by its real name and confirm what answered.** Run `apt install tealdeer`, never `apt install tldr` — the latter is a transitional stub that pulls the Haskell client (`Depends: tldr-hs`, shown above). Then verify the binary is the one you think:

```console
$ tldr --version
tealdeer 1.6.1
```

If that doesn't say `tealdeer`, some other implementation owns your `tldr` command and every assumption in this review is off. You can't secure a tool you can't name.

**2. Set `auto_update = false` and update by hand, then prove the cache is real.** Because `--update` returns exit 0 on a garbage download, never trust its exit code and never let it run silently on every invocation. Update on purpose, then count the pages — a real cache has thousands, a poisoned or empty one has a handful:

```console
$ tldr --update && tldr --list | wc -l
```

On a healthy cache that number is in the thousands. If you ran `--update`, it printed "Could not update cache," and `--list` shows five entries, you now *know* — instead of pasting from whatever your network last handed you. That two-command check is the whole mitigation: it converts a silent exit-0 lie into a number you can see.

**3. Read the whole rendered line before you run it, and keep `man` for the flags.** tldr is five crowdsourced examples where the destructive command wears the same cyan as the safe one. Treat every page as a suggestion from a stranger who's usually right: read the entire line, expand the `{{placeholders}}` yourself instead of pasting them, and when the flags matter — when the command touches files you can't recreate — spend the 1164 lines. The reader is the protagonist here. You reach for tldr because reading the manual is friction; just don't let "I saw it in cyan" become your entire trust model for a command you're about to run as yourself.

## Should you use it

Yes. I do, daily, and I'm not giving it up — the offline speed and the `[c]reate`/`[f]ile` bracket notation are worth the install by themselves, and the tldr-pages project genuinely maintains those examples well. But install `tealdeer` by name, turn `auto_update` off, update deliberately and check the page count, and remember that the friendly cyan is rendering a stranger's suggestion, not a signed contract. The free alternative is `man`, which is slower, longer, and has never once downloaded a fresh copy of itself over your coffee-shop WiFi and told you the failure was a success. tealdeer trades that boredom for speed. Take the trade — with your eyes open, and your `auto_update` off. Reality was reached for comment about why a failed download exits 0, and declined.
