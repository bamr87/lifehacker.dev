---
title: "Your .txt is a JPEG: file reads the bytes, not the extension"
description: "file reads the magic number, not the name, so a report.txt that's secretly a JPEG can't fool it. Where that saves you, and the three places it quietly lies."
date: 2026-09-08
preview: /images/previews/your-txt-is-a-jpeg-file-reads-the-bytes-not-the-ex.svg
categories: [Hacks]
tags: [shell, security]
author: edge
excerpt: "I renamed a JPEG to report.txt to see who I could fool. file was not fooled. I ran it 10,000 times to be sure."
permalink: /hacks/your-txt-is-a-jpeg/
---
The extension is a costume. The bytes are the truth. I know this because I spent an afternoon dressing a JPEG up as a text file to see who I could fool, and the only thing in the room that refused to play along was a program from 1986.

The claim under test, from the [Bashcrawl "Cellar" quest](https://it-journey.dev/quests/0000/cellar/) that put me up to this: `file` ignores the name on the door and reads the first few bytes — the *magic number* — to tell you what a thing actually is. And `ls -F` stamps a one-character tag on each entry so you can read *type* at a glance. Both are offline, both ship on every box I could find, and both have exactly the failure modes you'd expect from a 40-year-old heuristic and a display flag. I tested them the way I test everything: by lying to them on purpose.

## The setup: a lineup of liars

I made eight files. Every one of them has an extension that is either honest or a bald-faced lie about its contents.

```bash
# a real JPEG wearing a .txt costume
printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xd9' > report.txt
# a real ZIP wearing a .png costume
zip -q archive.zip payload.txt && mv archive.zip archive.png
# an ELF header wearing a .doc costume
printf '\x7fELF\x02\x01\x01\x00' > notes.doc
# a gzip stream wearing a .csv costume
printf '\x1f\x8b\x08\x00' > data.csv
printf 'hello, world\n' > real.txt   # honest
: > empty.txt                         # nothing at all
printf 'echo hi\n' > runme.sh         # a "script" with no shebang
printf '#!/bin/bash\necho hi\n' > proper.sh && chmod +x proper.sh
```

Then I asked `file` who each of them really was.

```console
$ file report.txt archive.png notes.doc data.csv real.txt empty.txt runme.sh proper.sh
report.txt:  JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16
archive.png: Zip archive data, at least v1.0 to extract, compression method=store
notes.doc:   ELF 64-bit LSB (SYSV)
data.csv:    gzip compressed data
real.txt:    ASCII text
empty.txt:   empty
runme.sh:    ASCII text
proper.sh:   Bourne-Again shell script, ASCII text executable
```

Every costume came off. Here's the scorecard I actually recorded (`file-5.45`, `coreutils 9.4`):

| File | Extension claims | `file` verdict | Fooled? |
|---|---|---|---|
| `report.txt` | text | JPEG image data | ❌ |
| `archive.png` | PNG image | Zip archive data | ❌ |
| `notes.doc` | Word doc | ELF 64-bit binary | ❌ |
| `data.csv` | CSV | gzip compressed data | ❌ |
| `real.txt` | text | ASCII text | ✅ (honest) |

You'll know it worked when `file report.txt` says `JPEG` and your file manager, which trusts the extension, is still showing you a broken-image thumbnail and blaming you.

Why do I care about a party trick? Because "trust the extension" is how a `.pdf` that is actually a Windows executable gets double-clicked, and how a build script `curl`s a "tarball" that is actually an HTML error page and then `tar` vomits. `file thing` *before* you open or run `thing` is a five-keystroke sanity check that reads the payload, not the label. That's the whole hack. Now the part where I break it.

## Footgun 1: file reads the content, so "empty" and "text" mean *nothing runnable*

`file` is not psychic. It reports what the bytes *are*, which is not the same as what you *meant*. Look back at two rows I skipped:

```console
$ file empty.txt runme.sh
empty.txt: empty
runme.sh:  ASCII text
```

`empty.txt` is `empty` — fine, technically true, spectacularly unhelpful when you were expecting the config you *thought* you wrote there. And `runme.sh` is just `ASCII text`, not a "script," because I forgot the shebang. Compare `proper.sh`, which earned the words `Bourne-Again shell script, ASCII text executable` by having a `#!/bin/bash` line and the execute bit.

**The failure this prevents:** you `chmod +x runme.sh` and it "runs" only because your current shell is bash — ship it to a `sh` box, or a cron job with a different `$SHELL`, and it does something else or nothing. If `file` won't call it a script, the kernel might not either. The shebang is not decoration; it's the thing that makes the file portable, and `file` is telling you it's missing.

## Footgun 2: how much magic is enough magic (the test that surprised me)

Here's where the third ridiculous experiment found the real bug. I assumed the JPEG magic was the two-byte "start of image" marker `FF D8`, so I made files with just the first one, two, and three bytes and asked `file` to identify them:

```console
$ printf '\xff\xd8\xff' > tiny.jpg;  file -b tiny.jpg
ISO-8859 text, with no line terminators
$ printf '\xff\xd8'     > two.jpg;   file -b two.jpg
ISO-8859 text, with no line terminators
$ printf '\xff'         > one.jpg;   file -b one.jpg
very short file (no magic)
```

Three bytes of genuine JPEG signature, and `file` called it *text*. It wants the whole APP0/JFIF segment — the full 20-byte header my `report.txt` had — before it's willing to say "JPEG." 

**The failure this prevents:** a truncated download or a corrupted image that lost its header will be confidently mislabeled as text, and any pipeline branching on `file`'s answer will route it wrong. `file` is a heuristic reading a fixed prefix (default 256 KB, `-P bytes` to change it), not a validator. It tells you what the *front* of the file looks like. It does not tell you the file is intact.

And the reverse costume — prose wearing a `.jpg` — comes off just as easily, which is the reassuring direction:

```console
$ printf 'This is just prose.\n' > selfie.jpg; file -b selfie.jpg
ASCII text
```

## Footgun 3: the ls -F markers are paint, not filename

`ls -F` (aka `--classify`) is the type-at-a-glance half of this. It appends one character per entry: `/` for a directory, `*` for an executable, `@` for a symlink (also `=` sockets, `|` FIFOs).

```console
$ ls -F
archive.png  empty.txt   notes.doc   proper.sh*  report.txt  subdir/
data.csv     link.txt@   real.txt    runme.sh
```

`proper.sh*` is executable, `link.txt@` is a symlink, `subdir/` is a directory. Read at a glance, exactly as advertised. Then someone copies a name straight out of that output into a command, and the paint comes with it:

```console
$ cat link.txt@
cat: link.txt@: No such file or directory
$ cat link.txt
hello, world
```

There is no file named `link.txt@`. The `@` is a display marker `ls` painted on; the real name is `link.txt`. **The failure this prevents:** a script that scrapes `ls -F` output (please don't, but people do) inherits phantom `*`/`@`/`/` characters and every path breaks. Worse is the `*`, because it's a glob:

```console
$ file proper.sh*
proper.sh: Bourne-Again shell script, ASCII text executable
```

That *looks* like it worked. It didn't — the shell expanded `proper.sh*` as a wildcard that happened to match `proper.sh`, so you got the right answer for entirely the wrong reason. Add one more file named `proper.sh.bak` and the same command silently starts operating on two files. A footgun that gives the correct answer during testing is the worst kind, because it waits.

The fix is to never treat `-F` output as names. When you need to *read* a hostile filename, ask `ls` to escape it (`ls -Fb` C-escapes, `ls -FQ` quotes) and when you need to *feed* names to another command, don't go through `ls` at all — go through `find -print0 | xargs -0`.

## The Tuesday test: hostile filenames

This is the part I get paid for. What happens when the filename itself is a weapon? I named three files with a newline, an emoji, and a SQL-injection string, then asked both tools to cope.

```console
$ ls -F
'; DROP TABLE users;--.doc
ev
il.txt
📸.png
```

The newline in `ev<newline>il.txt` makes plain `ls -F` print it across **two lines**, so a human skims right past it as two files, and a naive `for f in $(ls)` loop splits it into two nonexistent paths. `ls -Fb` tells the truth by escaping it:

```console
$ ls -Fb
';\ DROP\ TABLE\ users;--.doc   ev\nil.txt   📸.png
```

And `file`, fed the names NUL-safely, unmasked all three costumes without tripping over a single hostile byte — it even escaped the embedded newline as `\012` so its own output stays one-line-per-file:

```console
$ find . -maxdepth 1 -type f -print0 | xargs -0 file --mime-type
./ev\012il.txt:               image/jpeg
./📸.png:                     application/gzip
./'; DROP TABLE users;--.doc: application/octet-stream
```

The emoji `.png` was gzip. The SQL-injection `.doc` was a binary. The newline `.txt` was a JPEG. Grudgingly: `file` did not flinch, and `--print0 | xargs -0` is the only way I trust to carry those names between two programs without one of them mangling a byte into a bug.

## Does it survive a Tuesday?

I pinned the JPEG's verdict and re-ran `file -b report.txt` **10,000 times** to see if the heuristic ever wavered.

| Runs | Identical verdict | Disagreed | Wall time |
|---|---|---|---|
| 10,000 | 10,000 ✅ | 0 | 18s |

Deterministic. Boring. Exactly what I want from a program I'm about to trust with "is this thing safe to open."

**Verdict: survives a normal Tuesday, and a bad one.** `file thing` before you open or run it is a real reflex worth building; `ls -F` is a genuine at-a-glance convenience. It survives even the Tuesday where the intern has sudo and a filename with a newline in it — *as long as* you remember what it's actually telling you. `file` reads the front of the bytes, not the whole file and not your intentions; the `-F` markers are paint, not names; and three bytes of the right magic still isn't enough magic. Every one of those is a real bug I watched happen. Now you get to not.
