---
title: "pv: the progress bar for pipes that counts to 134% when it doesn't know the size"
description: "A stress-tested review of pv, the pipe viewer: the silent-when-piped default, the 1000% bar, the numeric mode that never stops climbing, and what survived."
date: 2026-10-30
preview: /images/previews/pv-the-progress-bar-for-pipes-that-counts-to-134-w.svg
categories: [Tools]
tags: [data, system]
author: edge
verdict: "Use it — survives a bad Tuesday. The bytes come out perfect every time; the percentage is only as honest as the size you gave it, and with no size it isn't a percentage at all."
excerpt: "I asked pv how far along a stream of unknown size was, in numbers, for a progress dialog. It said 2, then 4, then 6, and finished at 134. The bytes were perfect. The percent was fiction."
permalink: /tools/pv-honest-review/
---
I review tools by finding the number on the screen that people quote in Slack and checking whether it is true. `pv`, the pipe viewer, is the tool you wedge into the middle of a pipeline the moment you've stared at a frozen `gzip` for long enough to wonder whether it's working or whether the server has quietly died. You put `pv` where `cat` was, and you get a byte count, a rate, an elapsed time, a bar, and — if it knows the size — a percentage and an ETA. It's a tiny, old, wonderful idea.

It's also a tool whose most quotable output, the percentage, is only as honest as whatever you told it about the size. Tell it nothing and it guesses nothing on the bar, which is fine. Ask it for that same number in machine-readable form and it invents one. I found that on my third absurd scenario, which is exactly when the house rules say I would.

**The verdict, up front:** use it. In 1,000 runs through a filename built to hurt it, it passed every byte through unchanged. Its rate limiter held to 0.6% of the target, and it can attach to a process that's already running and tell you how far along it is. It survives a normal Tuesday and a bad Tuesday. It does not quite survive the Tuesday where the intern has sudo, because the intern is going to wire `pv -n` into a progress dialog for a stream of unknown size, and the dialog is going to say 134%.

Everything below ran on Ubuntu 24.04 with the packaged build:

```console
$ pv --version
pv 1.8.5
Copyright 2023 Andrew Wood
License: GPLv3+ <https://www.gnu.org/licenses/gpl-3.0.html>
```

`sudo apt-get install pv` and you're done. It's also in Homebrew and every other package manager I've met, and it has been for a very long time. My test subject was a 10 MiB file of `/dev/urandom` called `blob.bin`. One capture note: `pv` redraws its line in place with carriage returns, so for every bar shown below I piped stderr through `tr '\r' '\n'` and kept the final frame. The frames are real. The trimming is mine.

## Surprise one: in a script, it says nothing at all

The first thing I did was the first thing everyone does in CI: run it with stderr going somewhere that isn't a terminal.

```console
$ pv blob.bin > /dev/null 2>err.txt; echo "exit=$? stderr_bytes=$(wc -c < err.txt)"
exit=0 stderr_bytes=0
```

Zero bytes. That's on purpose: `pv` only draws when stderr is a terminal, so a cron job doesn't fill your logs with ten thousand carriage returns. **The failure this prevents you from misdiagnosing:** you add `pv` to a CI step to finally see progress on that slow restore, the log stays blank, and you spend twenty minutes deciding `pv` is broken. It isn't. Add `-f` (force) and it draws anyway:

```console
$ pv -f blob.bin > /dev/null
10.0MiB 0:00:00 [6.30GiB/s] [================================>] 100%
```

Six gigabytes a second, because it was reading a cached file and writing to `/dev/null`. That is a real number and also not one you'll ever see in production. Don't put it in a slide.

## Surprise two: the percentage believes whatever you tell it

When `pv` gets a filename, it stats the file and knows the size. When it reads from a pipe, it has no idea, and the bar turns into a bouncing `<=>` with no percentage. That's the honest answer:

```console
$ cat blob.bin | pv -f > /dev/null
10.0MiB 0:00:00 [1.54GiB/s] [<=>                                               ]
```

You can tell it the size with `-s`. It takes you at your word, completely. I gave it 10 MiB of data and told it there'd be 1 MiB:

```console
$ cat blob.bin | pv -f -s 1M > /dev/null
10.0MiB 0:00:00 [1.96GiB/s] [================================] 1000%
```

**1000%.** No warning and no clamp; the bar just fills up and the number keeps going. Then I lied in the other direction, saying 1 GiB:

```console
$ cat blob.bin | pv -f -s 1G > /dev/null
10.0MiB 0:00:00 [1.48GiB/s] [>                                ]   0%
```

It finished the job and reported 0%. **The failure this prevents:** you estimate a database dump's size from yesterday's dump with `-s`, today's is double, and the overnight log says 200% while somebody asks whether it ran twice. Or today's is half, the log stops at 50%, and somebody files an incident because "the backup died halfway." It didn't. The dump finished. Only your guess was wrong.

There's a sharp edge going the other way too, and this one is useful: `-S` makes `pv` *stop* after `-s` bytes, which turns it into a byte-exact `head -c` with a progress bar:

```console
$ cat blob.bin | pv -q -S -s 1000 | wc -c; echo "pipestatus=${PIPESTATUS[*]}"
1000
pipestatus=141 0 0
```

Exactly 1,000 bytes. The 141 belongs to `cat`, which got SIGPIPE when `pv` stopped reading. `pv` itself exited 0. Keep that in mind; it comes back later.

## Surprise three: the numeric mode counts past 100 and keeps going

This is the one I'd tattoo on the man page. `-n` is the machine-readable mode: instead of a bar, `pv` prints one integer percentage per line on stderr, "suitable for piping (via convoluted redirection) into dialog(1)," as the man page cheerfully puts it. With a real file it does exactly that:

```console
$ pv -n -f -i 0.1 -L 40M blob.bin 2>&1 > /dev/null | tr '\n' ' '
40 80 100
```

Lovely. Now the same thing on a pipe, where `pv` has already told us it doesn't know the size:

```console
$ cat blob.bin | pv -n -i 0.1 -L 4M 2>&1 > /dev/null | tr '\n' ' '
2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50
```

It finished at **50**. The stream was done, and the "percentage" said halfway. I made the stream longer to see whether it would stop at 100:

```console
$ head -c 7000000 blob.bin | pv -n -i 0.05 -L 1M 2>&1 > /dev/null | tr '\n' ' '
2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 122 124 126 128 130 132 134
```

It went straight past 100 and stopped at **134**. I ran it again and got 134 again, so this isn't a fluke of timing. It's what `pv` does. With no size, the number it prints is not a fraction of anything. It just goes up by 2 on every update interval. The visual bar knows this and switches to the bouncing `<=>`. Numeric mode doesn't, and it hands your progress dialog a counter labeled as a percentage. **The failure this prevents:** the installer that pipes `curl | pv -n | tar` into `dialog --gauge` because the server didn't send a `Content-Length`. Your user watches the gauge stop at 50% and kills a download that had finished. Or, on a slower link, they watch the gauge hit 100% while the download is nowhere near done.

The fix is in the same man page paragraph: if you don't know the size, ask for `-n -b`, which reports bytes instead of percent, and that number is always true:

```console
$ cat blob.bin | pv -nb -f -i 0.1 -L 40M 2>&1 > /dev/null | tr '\n' ' '
4194304 8388608 10485760
```

10,485,760 bytes is exactly 10 MiB. If you need a percentage, pass a real `-s`, or pass a file instead of a pipe. Either way, use `-n` alone only when `pv` actually knows the size.

## The exit codes: one quiet partial, one polite hang-up

**A missing file in the middle of the list.** `pv` concatenates files like `cat`. I gave it three files, with a missing one in the middle:

```console
$ pv blob.bin nope.bin "$f" > out.bin; echo "exit=$? outbytes=$(wc -c <out.bin)"
pv: failed to read file: nope.bin: No such file or directory
exit=2 outbytes=11534336
```

That's exit 2, so good. But `out.bin` is 11,534,336 bytes, which is the 10 MiB file plus the 1 MiB file after the gap. It skipped the hole and kept writing, the way `cat` does. **The failure this prevents:** a script that checks "did the output file appear and is it big" and not `$?` will happily ship a concatenation that's missing a piece. Check the exit code, or `set -e`.

**The reader hangs up early.** This is where `pv` differs from `cat`. When the downstream command stops reading after ten bytes, `cat` dies of SIGPIPE and reports 141, but `pv` exits 0. I ran it five times each to make sure:

```console
$ for i in 1 2 3 4 5; do pv blob.bin | head -c 10 >/dev/null; echo -n "pv=${PIPESTATUS[0]} "; cat blob.bin | head -c 10 > /dev/null; echo "cat=${PIPESTATUS[0]}"; done
pv=0 cat=141
pv=0 cat=141
pv=0 cat=141
pv=0 cat=141
pv=0 cat=141
```

And under `set -o pipefail`, where that difference decides whether your script fails:

```console
$ bash -c 'set -o pipefail; pv blob.bin | head -c 10 >/dev/null; echo "pipeline exit=$?"'
pipeline exit=0
$ bash -c 'set -o pipefail; cat blob.bin | head -c 10 >/dev/null; echo "cat pipeline exit=$?"'
cat pipeline exit=141
```

I'll grudgingly call this a feature. The classic `pipefail` papercut is `producer | head` failing a script that did exactly what you asked, and swapping `cat` for `pv` makes that 141 go away. **The failure to watch for:** `pv`'s exit 0 means "I stopped because you stopped listening," not "the consumer succeeded." If the consumer crashed, its own non-zero status still trips `pipefail`, so don't read `pv`'s 0 as proof that everything downstream worked.

## The gauntlet it survived

The bytes are the job, so I built the filename nobody should ever have: a newline, a floppy-disk emoji, and a SQL injection.

```console
$ f=$'evil\nname 💾 \x27; DROP TABLE files;--.bin'; head -c 1048576 blob.bin > "$f"
$ want=$(sha256sum < "$f" | cut -c1-64); ok=0; bad=0
$ for i in $(seq 1 1000); do got=$(pv -q -- "$f" | sha256sum | cut -c1-64); [ "$got" = "$want" ] && ok=$((ok+1)) || bad=$((bad+1)); done; echo "ok=$ok bad=$bad"
ok=1000 bad=0
```

All 1,000 runs were byte-identical. (Full disclosure: my *first* attempt at that loop reported `ok=0 bad=1000`, because I'd globbed the filename with `evil*` from inside an `ls | grep`, and the newline split it in two. That failure was mine. `pv` never got a fair shot until I quoted the name properly. So the evil filename found a bug in the tester, which is also on-brand.)

Then the rate limiter, which is the other reason people install `pv`, to stop a backup from saturating the link everyone else is using:

```console
$ s=$(date +%s.%N); head -c 5242880 blob.bin | pv -q -L 1M > /dev/null; e=$(date +%s.%N); echo "5MiB at -L 1M took $(echo "$e - $s" | bc) s"
5MiB at -L 1M took 4.968343337 s
```

5 MiB at 1 MiB/s should take 5 seconds. It took 4.97, about 0.6% fast, and the gap is the first second's burst. It's a throttle you can trust.

Line mode (`-l`) counts lines instead of bytes, which is the right unit for "how many rows has this import chewed through":

```console
$ seq 1 100000 | pv -l -f > /dev/null
 100k 0:00:00 [36.2M/s] [ <=>                                                  ]
```

And my favourite trick: `-d PID` attaches to a process that's *already running* and shows progress on every file it has open, so you can check the `cp` you forgot to pipe through `pv` without restarting it. I started a deliberately slow Python reader on `blob.bin` and pointed `pv` at its PID:

```console
$ timeout 3 pv -d "$p" -f -i 1
   3:blob.bin: 7.81MiB 0:00:01 [3.12MiB/s] [=============>    ]  78% ETA 0:00:00
```

It found file descriptor 3, named the file, knew its size, and gave a real percentage and ETA for a process it had never touched. That's the one I'd show someone first.

## The results table

| Scenario | Result | |
| --- | --- | --- |
| stderr not a tty, no `-f` | silent, exit 0 | ✅ by design |
| `-s 1M` on 10 MiB | bar reads 1000% | ❌ trusts your lie |
| `-s 1G` on 10 MiB | finishes at 0% | ❌ trusts your lie |
| `-n` with no known size | "percent" ends at 50, or at 134 | ❌ not a percentage |
| `-nb` with no known size | 10485760 bytes, exact | ✅ |
| missing file mid-list | exit 2, rest still written | ✅ if you check `$?` |
| reader hangs up early | `pv` exit 0 (`cat`: 141) | ✅ friendlier under `pipefail` |
| hostile filename, 1,000 runs | 1,000/1,000 hashes match | ✅ |
| `-L 1M`, 5 MiB | 4.97 s | ✅ |
| `-d PID` on a running reader | 78%, real ETA | ✅ |

## Who it's for, the price, and the alternatives

Free, GPLv3, one small binary, in every package manager. Use it whenever a pipeline runs long enough to make you nervous, whenever you need to throttle one, and whenever you've started a long copy without it and want to know how it's going (`-d`). If you're benchmarking rather than watching, that's a different tool, and [hyperfine](/tools/hyperfine-honest-review/) will warn you about its own noise, which `pv` won't. If the real problem is a dozen slow jobs instead of one, [GNU parallel](/tools/gnu-parallel-honest-review/) has its own `--bar`. And if you're already living in [moreutils](/tools/moreutils-honest-review/), nothing in that box shows progress, so `pv` fills the gap.

The free alternative is the one already on your machine: GNU `dd` has `status=progress`, which prints a running byte count with no percentage. That makes it more honest than `pv -n` on a pipe, and a lot less pleasant to look at.

**Final verdict:** use it. It survives a bad Tuesday. In 1,000 runs it never corrupted a byte, its throttle is accurate, and `-d` is a little bit of magic. Just treat its percentage as a function of your input, not a measurement. Give it a file or a true `-s` and the percentage is real. Give it a guess and the percentage is your guess. Give it nothing and ask for a number anyway, and it'll count to 134 with a straight face.
