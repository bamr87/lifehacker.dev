---
title: "hexedit: the honest review"
description: "hexedit, the TUI hex editor that writes where hexyl only reads: the overwrite-in-place model, the no-insert limit, and the 'needs a real terminal' dealbreaker."
date: 2026-07-07
collection: tools
author: claude
verdict: "Use it for eyeball-and-nudge byte edits on a real terminal — but it overwrites in place, can't insert a byte, and won't script"
excerpt: "The hex editor hexyl can't be. It actually writes bytes. Free. Verdict: keep it for hand-editing a binary at a real terminal, but reach for xxd -r the moment you need to insert, grow, or script."
tags: [cli, binary, developer-tools]
---

**Verdict: install it for the one thing our favorite hex *viewer* refuses to do — change a byte — and stop the moment you need to insert one, grow the file, or run it from a script.** [`hexyl`](/tools/hexyl-honest-review/) is the nicest way to *read* a binary in a terminal, and its own headline caveat is that it can only read: there is no reverse, no write. `hexedit` is the sibling that closes that loop. It's a full-screen ncurses editor that shows a file in hex and ASCII and lets you overwrite bytes in place. That last phrase — *in place* — is both the whole point and the whole limitation. We ran everything below on Ubuntu 24.04 with `hexedit 1.6-1`.

`hexedit` is free and open source (GPL). We have no relationship with the project and nothing to sell. As with its modern-CLI cousins the catch isn't price or telemetry — it's a couple of defaults and one hard limit that ambush anyone arriving from a text editor. We'll show you exactly where.

## Install — and, unusually, the name behaves

```bash
brew install hexedit          # macOS
sudo apt install hexedit      # Debian/Ubuntu
```

If you read our [`fd`](/tools/fd-honest-review/) or [`bat`](/tools/bat-honest-review/) reviews you're braced for the Debian rename tax — `fd` shipping as `fdfind`, `bat` as `batcat`. Not here. `hexedit` keeps its name:

```bash
$ dpkg -l hexedit | tail -1
ii  hexedit  1.6-1  amd64  viewer and editor in hexadecimal or ASCII for files or devices
$ dpkg -L hexedit | grep bin/
/usr/bin/hexedit
```

The command on your `PATH` is `hexedit`, the same word every tutorial types.

## The pairing: read with hexyl, write with hexedit

The natural workflow is two tools, not one. Use `hexyl` to *find* the byte — its category colors make a file header legible at a glance:

```bash
$ hexyl --border ascii pair.bin
+--------+-------------------------+-------------------------+--------+--------+
|00000000| 48 65 6c 6c 6f 2c 20 77 | 6f 72 6c 64 21 0a       |Hello, w|orld!_  |
+--------+-------------------------+-------------------------+--------+--------+
```

(Shown with `--border ascii` so it renders in this code block; the real thing is in color.) Now you know byte `00` is `0x48`, an `H`. To *change* it you switch tools, because `hexyl` doesn't write. That's where `hexedit` earns its keep.

## The edit model: it overwrites, and that's the surprise

Open a file, and the cursor sits on the first byte in the hex pane. Type two hex digits and you've **overwritten** that byte — no insert mode, no shifting the rest of the file down. We changed byte `00` from `0x48` (`H`) to `0x4a` (`J`), saved with `Ctrl-W`, and quit. Here's the file before and after, straight from `xxd`:

```console
$ xxd hexdemo.bin        # before
00000000: 4865 6c6c 6f2c 2077 6f72 6c64 210a       Hello, world!.
$ xxd hexdemo.bin        # after: 0x48 -> 0x4a, and NOT ONE byte longer
00000000: 4a65 6c6c 6f2c 2077 6f72 6c64 210a       Jello, world!.
```

`Hello` became `Jello`, and the file is still exactly 14 bytes. That is the model in one line: **you edit bytes, you never edit *length*.** If you came from a text editor, that's the muscle-memory trap. In `vim` or `nano`, typing a character pushes everything after it to the right. In `hexedit`, typing a character annihilates the one under the cursor. There's no "insert a byte here and slide the rest along." The man page bears this out — its command list has search, copy, paste, fill, and *truncate* (`Esc+T`), but no insert. The only way to change a file's size is to cut it shorter.

Two small mercies in the interface make this survivable:

- **Backspace is undo, not delete.** It reverts your change to the previous byte instead of removing a byte (which would be meaningless in an overwrite editor). `Ctrl-U` undoes everything.
- **The modeline tells you the truth.** The bottom bar copies emacs: `--` means unmodified, `**` means you've changed something unsaved, `%%` means read-only. Glance there before you `Ctrl-C` (quit *without* saving) instead of `Ctrl-W` (save).

## The dealbreaker: it needs a real terminal

Here is the line that decides whether `hexedit` belongs in your automation. It does not:

```console
$ hexedit somefile < /dev/null
Error opening terminal: unknown.
$ echo $?
1
```

`hexedit` is an ncurses program. Point anything but a live terminal at it — a pipe, a redirect, a CI job, a `cron` entry — and it dies before it edits a single byte. There is no batch mode, no `--script`, no `-e 'command'`. Every edit is a human at a keyboard. (We *did* drive it for this review by allocating a real pseudo-terminal and feeding it keystrokes, which is exactly the kind of contortion that proves the point: if scripting a hex edit takes a PTY harness, you wanted a different tool.)

That different tool is one you already have. `xxd -r` reverses a hex dump back into bytes, so a dump-edit-reverse round trip is fully scriptable — and, unlike `hexedit`, it can build a file of *any* length:

```console
$ printf '00000000: 4865 7921 0a\n' | xxd -r > out.bin
$ wc -c < out.bin
5
$ xxd out.bin
00000000: 4865 7921 0a                             Hey!.
```

`hexedit` could never have produced that from a 14-byte file — it can only overwrite the 14 bytes it started with (or truncate). `xxd -r` builds five bytes from a text line in a pipe with no terminal in sight. For anything a script does, `xxd -r` (or `perl`/`printf`) wins outright.

## What it costs and the free alternative

It costs nothing — GPL, no account, no telemetry. And the "free alternative" is the same tool that's the honest alternative: `xxd` (bundled with Vim) plus your normal text editor, or `od`/`hexdump -C` for reading. The trade is *ergonomics versus reach*. When a human needs to poke one byte in a binary and see the ASCII update live — flip a flag in a header, blank out a magic number to test error handling — `hexedit` is genuinely pleasant and faster than the dump-edit-reverse dance. The instant the edit needs to be repeatable, scripted, or change the file's size, `hexedit` can't help and `xxd -r` can.

## When to use which

- **Reach for `hexyl`** to *read* a binary. It's the best viewer here and it's [reviewed next door](/tools/hexyl-honest-review/). It will not write.
- **Reach for `hexedit`** to hand-edit a byte or two on a real terminal, watching the ASCII column react. Same-length tweaks only.
- **Reach for `xxd -r`** the moment you need to insert or delete bytes, change the file length, or do any of it from a script.

## What made us close the tab

Nothing made us uninstall it — it does a real job the viewer can't. But the caveats, in the order they'll bite you:

- **It overwrites; it can't insert.** No byte-insert, no grow-in-the-middle. Same length in, same length out (or shorter, via `Esc+T` truncate). If you need to *add* a byte, you need `xxd -r`.
- **It needs a live terminal.** Pipe or redirect it and you get `Error opening terminal: unknown` and exit 1. There is no batch mode. It is the opposite of scriptable, on purpose.
- **`Ctrl-W` saves, `Ctrl-C` discards, `Ctrl-X` quits.** Three different exits and the panic key (`Ctrl-C`) is the one that throws your edits away. Watch the `**` in the modeline before you leave.

**When it goes wrong:** if a script hangs or dies the instant it calls `hexedit`, it's the terminal requirement — you wanted `xxd -r` and a pipe. If your file came out one byte short or long, `hexedit` didn't do it — it can't change length except by truncating, so a size change means the round trip was through something else. And if you're hunting for the "insert byte" key: you're not missing it. `hexedit` overwrites, the same way `hexyl` only reads — each tool is exactly, and only, what its name says.
