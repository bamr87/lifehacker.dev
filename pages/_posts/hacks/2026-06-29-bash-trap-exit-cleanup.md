---
title: "Make your bash scripts clean up after themselves: trap … EXIT"
description: "One trap line cleans up a script's temp dir on success, error, or Ctrl-C — plus the empty-variable rm -rf that makes it dangerous and the signal it can't catch."
date: 2026-06-29
categories: [Hacks]
tags: [shell]
author: claude
excerpt: "A script that makes a temp dir and then errors out leaves the temp dir behind. One trap line fixes that — and one wrong trap line tries to rm -rf the root. Both stay in."
preview: /images/previews/section-hacks.svg
permalink: /hacks/bash-trap-exit-cleanup/
---
You wrote a script that does strict-mode the right way: it [fails loudly](/hacks/bash-strict-mode-fail-loudly/) the moment a command breaks. Good. Now follow the failure path. The script made a scratch directory in `/tmp`, got three commands in, hit an error, and — because it's strict — exited immediately. The scratch directory is still there. It will be there tomorrow, and so will the next forty, one per failed run, slowly turning `/tmp` into a landfill.

Here's that exact script. `mktemp -d` makes the workspace, then a `cp` fails:

```console
$ cat naive.sh
#!/usr/bin/env bash
set -euo pipefail
workdir=$(mktemp -d)
echo "working in $workdir"
cp /no/such/file "$workdir/"   # fails here
echo "never reached"
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
0
$ bash naive.sh; echo "exit=$?"
working in /tmp/tmp.sJ0n0BBIwK
cp: cannot stat '/no/such/file': No such file or directory
exit=1
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
1
```

Zero temp dirs before, one after. The script did its job — it stopped on the error — but it didn't take its mess with it. Wrapping the cleanup in an `if` or remembering to `rm -rf` on every exit path is how you end up with five `rm -rf` lines and still a leak on the path you forgot.

## The one line

`trap` registers a command to run when the shell receives a signal. The pseudo-signal `EXIT` fires whenever the script ends — normal finish, error exit, or killed by a signal. Register a cleanup against `EXIT` once, right after you create the thing, and you never think about it again:

```console
$ cat cleanup.sh
#!/usr/bin/env bash
set -euo pipefail
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
echo "working in $workdir"
cp /no/such/file "$workdir/"   # still fails here
echo "never reached"
$ bash cleanup.sh; echo "exit=$?"
working in /tmp/tmp.cvSc5JHEGh
cp: cannot stat '/no/such/file': No such file or directory
exit=1
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
0
```

Same error, same `exit=1` — but the temp dir is gone. **You'll know it worked when** a script that exits non-zero still leaves `/tmp` exactly as clean as it found it.

Here's the whole pattern as a self-contained, working script. This block is opted into our test harness (`lh:run`) and runs in a locked-down, no-network sandbox on every build, so the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

workdir=$(mktemp -d)                 # make the scratch space
trap 'rm -rf "${workdir:?}"' EXIT    # arm cleanup IMMEDIATELY after

echo "scratch space: $workdir"
echo "some intermediate work" > "$workdir/step1.txt"
wc -l "$workdir/step1.txt"

echo "done — the trap removes $workdir on the way out, whatever happens"
```

That exits `0` and leaves nothing behind. (The `${workdir:?}` instead of `$workdir` is not decoration — it's the difference between this hack and a disaster. Keep reading.)

## It also fires when someone kills the script

The reason `EXIT` beats a manual `rm -rf` at the bottom is the cases you don't control. Send the running script a `SIGTERM` (what a plain `kill`, a CI timeout, or a container shutdown sends) and the trap still runs:

```console
$ cat sig.sh
#!/usr/bin/env bash
set -euo pipefail
workdir=$(mktemp -d)
trap 'rm -rf "${workdir:?}"' EXIT
echo "$$ working in $workdir"
sleep 30
$ bash sig.sh & pid=$!
$ kill -TERM "$pid"; wait "$pid"; echo "exit=$?"
7225 working in /tmp/tmp.87t1628c97
[1]+  Terminated              bash sig.sh
exit=143
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
0
```

The script was killed mid-`sleep`, exited `143` (that's `128 + 15`, the signal number for `SIGTERM`), and the cleanup still ran. Ctrl-C (`SIGINT`, exit `130`) behaves the same way. The `EXIT` trap is the single place that covers all of them, which is why you register against `EXIT` and not against each signal by hand.

## The part where one wrong line tries to delete everything

This hack has teeth. The trap is only a string, and the shell expands it *later* — when the trap fires, not when you write it — so if `workdir` is empty at that moment, `rm -rf "$workdir/"` expands to `rm -rf "/"`. And the easiest way to make `workdir` empty is to arm the trap *before* the assignment, then have the script die in between:

```console
$ cat toosoon.sh
#!/usr/bin/env bash
# no set -u here, on purpose, to show the danger
trap 'rm -rf "$workdir/"' EXIT     # armed too early; workdir still empty
some_command_that_does_not_exist  # script dies BEFORE workdir is assigned
workdir=$(mktemp -d)
$ workdir=""; echo "rm -rf \"$workdir/\""
rm -rf "/"
```

The trap fires on the way out, `workdir` is still the empty string, and the command it runs is `rm -rf "/"`. That is the whole horror story of trap-based cleanup, and it's why two habits are mandatory.

**Habit one: assign first, then arm the trap.** The trap can't reference a variable that doesn't exist yet if you create the thing on the line above:

```console
$ cat rightorder.sh
#!/usr/bin/env bash
set -euo pipefail
workdir=$(mktemp -d)               # create FIRST
trap 'rm -rf "${workdir:?}"' EXIT  # THEN arm the trap
echo "ok, workdir=$workdir"
$ bash rightorder.sh; echo "exit=$?"
ok, workdir=/tmp/tmp.eF9X6sCEfy
exit=0
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
0
```

**Habit two: guard with `${workdir:?}`.** That syntax means "expand `workdir`, but if it's unset or empty, print an error and refuse." It turns the catastrophe into a harmless, loud failure no matter what order things ran in:

```console
$ cat guarded.sh
#!/usr/bin/env bash
set -euo pipefail
trap 'rm -rf "${workdir:?cleanup: workdir unset}"' EXIT
echo "about to fail before workdir exists"
false
workdir=$(mktemp -d)
$ bash guarded.sh; echo "exit=$?"
about to fail before workdir exists
guarded.sh: line 1: workdir: cleanup: workdir unset
exit=1
```

The script died before `workdir` was set, the trap fired, and `${workdir:?}` refused to run `rm -rf` on nothing instead of running it on everything. Use `${var:?}` in the trap and you have a seatbelt even on the day you reorder the file.

## When this goes wrong: the signal you can't catch, and the exit code

Two honest limits.

**`SIGKILL` (`kill -9`) cannot be trapped.** There is no signal handler for it — the kernel removes the process without telling it. So a `-9`'d script leaks its temp dir, and nothing you write can prevent that:

```console
$ bash kill9.sh & pid=$!
working in /tmp/tmp.v6WmMpgNgH
$ kill -9 "$pid"; wait "$pid" 2>/dev/null; echo "exit=$?"
exit=137
$ ls -d /tmp/tmp.* 2>/dev/null | wc -l
1
```

Exit `137` is `128 + 9`. The trap never ran; the dir survives. This isn't a bug in the hack — it's the deal with `SIGKILL`, and it's why long-lived services put scratch space under a path that a reboot or a `systemd-tmpfiles` sweep clears, rather than trusting cleanup alone. For ordinary scripts, `EXIT` covers everything except the `-9`, and that's enough.

**The trap doesn't clobber your exit code — unless you make it.** A common worry is that the cleanup's own success will mask the script's real failure. It won't; bash preserves the script's exit status across an `EXIT` trap:

```console
$ cat clobber.sh
#!/usr/bin/env bash
trap 'true' EXIT          # trap's last command succeeds
false                     # script's real status is 1
$ bash clobber.sh; echo "exit=$?"
exit=1
```

The failing status survived. The one way to lose it is to call `exit` *inside* the trap — so don't. If your cleanup needs the original status (to log it, say), grab it on the first line of the handler with `rc=$?` before you run anything else.

## The honest accounting

`trap 'rm -rf "${workdir:?}"' EXIT`, on the line right after `mktemp -d`. That's the hack. It costs you one line and the discipline to write `${var:?}` instead of `$var`, and in exchange every exit path — success, error, Ctrl-C, `kill` — leaves `/tmp` clean. It can't save you from `kill -9`, and it can quietly `rm -rf "/"` if you arm it empty, which is exactly why the guard isn't optional.

Make the temp dir. Arm the trap. Forget about cleanup forever.
