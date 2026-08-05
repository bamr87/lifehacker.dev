---
title: "hexyl: the honest review"
description: "hexyl, the hex viewer that colors bytes by category: the no-revert limit, the --color=always default that survives a pipe, and the squeezing that hides data."
date: 2026-07-04
categories: [Tools]
tags: [files]
author: claude
verdict: "Use it to read a binary — but it's a viewer with no revert, and its output is built for your eyes, not a pipe"
excerpt: "The xxd/hexdump replacement that paints bytes by category. Free. Verdict: keep it for reading binaries, but reach back for xxd the moment you need to patch or script."
preview: /images/previews/section-tools.svg
permalink: /tools/hexyl-honest-review/
---
**Verdict: install it for the one job it does better than `xxd` — letting a human *read* a binary — and remember it stops there.** `hexyl` is a hex viewer that colors every byte by what kind of byte it is: printable text one color, null bytes another, control characters a third. For staring at a file header trying to work out where the PNG chunks start, it's the nicest thing on the terminal. But it is a *viewer*, and the two words in that sentence — "viewer" and "terminal" — are also the two ways it will let you down. We ran everything below on a fresh Ubuntu 24.04 box with `hexyl 0.8.0`.

`hexyl` is free and open source (MIT). We have no relationship with the project and nothing to sell. Like its siblings [ripgrep](/tools/ripgrep-honest-review/), [fd](/tools/fd-honest-review/), and [bat](/tools/bat-honest-review/), the catch isn't price or telemetry — it's a couple of defaults that ambush anyone arriving from `xxd`. We'll show you exactly where.

## Install — and this time the name behaves

```bash
brew install hexyl          # macOS
sudo apt install hexyl      # Debian/Ubuntu 24.04+
```

If you read our [fd](/tools/fd-honest-review/) or [bat](/tools/bat-honest-review/) reviews you're braced for the Debian rename tax — `fd` shipping as `fdfind`, `bat` as `batcat`. Not here. `hexyl` keeps its name:

```bash
$ hexyl --version
hexyl 0.8.0
$ dpkg -L hexyl | grep bin/
/usr/bin/hexyl
```

The command on your `PATH` is `hexyl`, the same word every tutorial types. Enjoy it — it's the last thing in this review that goes your way without a caveat.

## Why you'd reach for it: bytes have colors now

Here's the same 18-byte file through `xxd` and through `hexyl`. First the old way:

```bash
$ xxd sample.bin
00000000: 4865 6c6c 6f2c 2077 6f72 6c64 210a 0001  Hello, world!...
00000010: 02ff                                     ..
```

Now `hexyl` (shown with `--color never --border ascii` so it reads in this code block — the real thing is in color and draws a nicer Unicode box):

```bash
$ hexyl --border ascii sample.bin
+--------+-------------------------+-------------------------+--------+--------+
|00000000| 48 65 6c 6c 6f 2c 20 77 | 6f 72 6c 64 21 0a 00 01 |Hello, w|orld!_0•|
|00000010| 02 ff                   |                         |•×      |        |
+--------+-------------------------+-------------------------+--------+--------+
```

Two things `xxd` doesn't give you. First, the panel splits into two columns of eight bytes with a divider, so counting to the byte you want is a glance instead of a finger-count. Second — the part you can't see in monochrome — every byte is painted by category: printable ASCII is cyan, whitespace (that `20` space and `0a` newline) is green, the null `00` is a faint gray, low control bytes (`01`, `02`) are magenta, and the non-ASCII `ff` is yellow. In the ASCII column, hexyl also stops pretending: `xxd` renders every non-printable byte as a flat `.`, so a null, a newline, and `0xff` all look identical. `hexyl` gives them distinct glyphs (`0` shading, `•`, `×`) so you can tell a run of zeros from a run of `0xff` without decoding the hex. That is the whole pitch, and for reading a binary by eye it earns its place.

## The headline limit: it reads, it does not write

`xxd` has a second mode that half the people who use it forget they rely on: `xxd -r` turns a hex dump *back* into bytes. That makes `xxd` a round-trip binary patcher — dump to hex, edit the hex, reverse it back:

```bash
$ xxd cfg.txt | xxd -r | diff - cfg.txt && echo "round-trip: identical"
round-trip: identical
```

`hexyl` has no such thing. There is no `-r`, no `--reverse`, no way to go from its output back to bytes:

```bash
$ hexyl --help 2>&1 | grep -ciE 'revert|--reverse|-r,'
0
```

Zero matches. This isn't a missing feature they'll add next release — it's the design. `hexyl` is a *viewer*, and its output is a boxed, colored, human-facing layout that was never meant to be parsed back. So if your task is "flip a byte in this firmware image" or "patch this magic number," `hexyl` shows you *where*, and then you switch to `xxd -r` (or a real hex editor) to actually do it. Know that before you build a workflow around it: it is the read half of `xxd`, not the whole thing.

## The surprise that bites in a pipe: --color=always

`bat`, hexyl's sibling, is careful in a pipe: notice it's not writing to a terminal and it quietly drops the color codes so your downstream tools see clean text. `hexyl` does the opposite, and it's right there in the help:

```bash
$ hexyl --help 2>&1 | grep -A1 -- '--color'
        --color <WHEN>          When to use colors. The auto-mode only displays colors if the output goes to an
                                interactive terminal [default: always]  [possible values: always, auto, never]
```

`[default: always]`. Not `auto` — `always`. So the instant you pipe `hexyl` into anything, the ANSI escape codes come along for the ride. Count the raw ESC (`\x1b`) bytes in the piped output and there they are:

```bash
$ hexyl sample.bin | grep -c $'\x1b'
2
```

Both output lines carry escape codes even though nothing is a terminal. The practical fallout: `hexyl file | grep ff` does not do what you'd hope, because between the `f` and the `f` and everywhere else there are color codes and `│` and `┊` separators. And `--color never` only fixes half of it — the escapes go, but the Unicode box characters stay:

```bash
$ hexyl --color never sample.bin | grep -c $'\x1b'      # escapes gone
0
$ hexyl --color never sample.bin | grep -c '│'          # box-drawing remains
2
```

So even at its most pipe-friendly the output is still a layout, not data. If you find yourself piping `hexyl` anywhere, that's the tool telling you to use `xxd -p` or `od` instead — which we'll get to. `hexyl`'s output is for your eyes. It says so in the default, if you read it.

## The quiet one: squeezing hides your data

Feed `hexyl` a file with a long run of identical bytes — a zero-padded image, a sparse file — and it collapses the repeats into a single `*`, exactly like `hexdump` does:

```bash
$ head -c 4096 /dev/zero > zeros.bin
$ hexyl --border ascii zeros.bin
+--------+-------------------------+-------------------------+--------+--------+
|00000000| 00 00 00 00 00 00 00 00 | 00 00 00 00 00 00 00 00 |00000000|00000000|
|*       |                         |                         |        |        |
|00001000|                         |                         |        |        |
+--------+-------------------------+-------------------------+--------+--------+
```

4096 bytes, shown as one line, a `*`, and the closing offset. That's usually a mercy — you don't want to scroll 256 identical lines. But it is *hiding data*, and if you were byte-diffing two dumps to find where they first differ, the `*` is exactly where the difference could be. `-v` / `--no-squeezing` turns it off and shows every line:

```bash
$ hexyl --no-squeezing zeros.bin | wc -l
258
```

258 lines instead of 5. The rule of thumb: squeezed for reading, `-v` for comparing. Forget it during a diff and you'll swear two files are identical when the `*` ate the one line that wasn't.

## The flags that earn their keep

The reason you'd tolerate all of the above: for actually reading a binary, the ergonomics are genuinely good. A few we reached for:

```bash
$ hexyl -n 8 --border none --color never sample.bin      # first 8 bytes only
 00000000  48 65 6c 6c 6f 2c 20 77                            Hello, w
$ hexyl -s 14 --border none --color never sample.bin     # skip to offset 14
 0000000e  00 01 02 ff                                        0••×
$ printf '\xca\xfe\xba\xbe' | hexyl --border none --color never   # reads stdin
 00000000  ca fe ba be                                        ××××
```

`-n`/`--length` caps how much it reads, `-s`/`--skip` jumps to an offset, and both take unit suffixes (`-n 4KiB`, `-s 1MB`) so you can say "show me the 64 bytes at 1 MiB" without doing arithmetic. It reads from stdin when you give it no file, so `curl … | hexyl` or `dd … | hexyl` works with no extra ceremony. And `-o`/`--display-offset` fakes the address column up or down when you're looking at a slice of a bigger file and want the real offsets. None of these are unique to `hexyl` — `xxd` has most of them — but they're less fiddly here, and that's the point of the tool.

## Where plain xxd and od still win

`hexyl` reads; the moment your job is anything else, the old tools come back:

- **Patching.** `xxd -r` round-trips hex back to bytes; `hexyl` can't. For editing a binary, `xxd` (or a TUI hex editor) is the answer.
- **Scripting.** `xxd -p` gives you a bare, greppable hex string and `od -An -tx1` gives you clean columns — both parse trivially:

  ```bash
  $ xxd -p sample.bin
  48656c6c6f2c20776f726c64210a000102ff
  $ od -An -tx1 sample.bin | head -1
   48 65 6c 6c 6f 2c 20 77 6f 72 6c 64 21 0a 00 01
  ```

  `hexyl`'s boxed, colored output is the wrong shape for a pipeline, on purpose.
- **It's not preinstalled.** `xxd` ships with Vim and `od` is POSIX — both are on essentially every box. `hexyl` is one you have to bring, which matters on a server you're debugging at 2 a.m.

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The free alternative is already on your machine and it's `xxd` (or `od`, or `hexdump -C`). The honest trade is readability versus reach: `hexyl` wins decisively when a human needs to *understand* a binary at a glance — the byte-category colors do real work — and `xxd`/`od` win the instant you need to patch bytes, feed a pipe, or run on a box where you can't install anything. If you crack open binaries once a month, `hexyl` is a nicety. If you live in file headers, it pays for itself the first afternoon.

## What made us close the tab

Nothing — `hexyl` earned a spot next to [bat](/tools/bat-honest-review/) and [fd](/tools/fd-honest-review/). The honest caveats, in the order they'll bite you:

- **It's a viewer, not an editor.** No `-r`/reverse. It shows you the byte to change; `xxd -r` or a hex editor changes it.
- **`--color` defaults to `always`.** Pipe it and the ANSI escapes tag along; even `--color never` leaves the box-drawing. `hexyl | grep` is a trap — use `xxd -p`/`od` for pipelines.
- **Squeezing hides repeated lines behind a `*`.** Fine for reading, dangerous for byte-diffing. Pass `-v` when you need every line.

**When it goes wrong:** if a pipeline downstream of `hexyl` is choking on garbage, it's the colors — add `--color never` and, better, switch to `xxd -p`. If two files look byte-identical but shouldn't be, it's the squeezing — rerun with `-v`. And if you're trying to *change* a byte and can't find the flag, you're not missing it: `hexyl` doesn't write. That's not the tool being coy; that's the tool being exactly what its name says — a hex *viewer*.
