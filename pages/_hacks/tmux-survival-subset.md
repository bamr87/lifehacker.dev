---
title: "tmux in 9 commands: the survival subset"
description: "The nine tmux commands that actually keep your work alive across disconnects, plus the four-line .tmux.conf that makes the defaults bearable."
date: 2026-06-24
collection: hacks
author: claude
excerpt: "tmux has hundreds of bindings. You need nine of them to stop losing your work to a dropped SSH connection."
tags: [tmux, shell, terminal, productivity]
---

tmux has a manual long enough to have its own table of contents. People write multi-part blog series about it. There is a 400-page book.

You do not need any of that to get the one thing tmux is actually for: your terminal session keeps running when your connection drops. The SSH tunnel dies, the laptop sleeps, the train goes into a tunnel — and the build you started two hours ago is still there when you come back.

Here is the subset that buys you that. Nine commands. Three you type at a normal shell, six you press inside tmux. That is the whole survival kit.

## The one idea you have to hold

tmux runs a **server** in the background. Inside it live **sessions**; inside a session live **windows** (like browser tabs); inside a window live **panes** (split views). You *attach* to a session to see it and *detach* to leave it running without you.

That's the model. Everything below is only navigation inside it.

## The three you type at the shell

These run from your normal prompt, before or after tmux is involved.

**1. Start a named session:**

```bash
tmux new -s work
```

Your terminal clears and you're inside. The `-s work` names it `work` so you can find it again — an unnamed session is only a number, and you will forget the number.

**2. List what's running:**

```bash
tmux ls
```

```text
work: 1 windows (created Wed Jun 24 23:48:05 2026)
```

That line is the entire point of tmux on one line: a session, alive, with a name you chose. Run this from outside tmux any time you've forgotten what you left running.

**3. Reattach to it:**

```bash
tmux attach -t work
```

Drop the connection, come back tomorrow, run that, and you are exactly where you left off — same windows, same panes, the long-running thing still running. This is the command that makes the other eight worth learning.

## The prefix: the key in front of everything else

The remaining six are *key presses inside tmux*, and they all start with the **prefix**. By default that's **`Ctrl-b`**: hold Ctrl, tap `b`, let go, then press the second key. We're going to change the prefix in a minute because `Ctrl-b` is a finger pretzel, but the pattern never changes — prefix, then the key.

We'll write it as `prefix` below. Read it as "do your prefix, then press this."

**4. Detach — leave it running, walk away:**

```text
prefix d
```

The session keeps running in the background; you're dropped back at your normal shell. This is the move. Start a long job, `prefix d`, close your laptop, reattach from a different machine later. Nothing was lost because nothing stopped.

**5. New window (a fresh full-screen tab):**

```text
prefix c
```

`c` for create. You get a clean prompt; your other window is still there. The status bar at the bottom shows them numbered, with a `*` on the one you're looking at:

```text
0: bash- (1 panes) ...  @0
1: logs* (1 panes) ...  @1 (active)
```

**6. Jump to window N:**

```text
prefix 0     (or 1, or 2...)
```

Each window has a number, visible in that status bar. `prefix 1` goes straight to window 1. This is faster than cycling, once you know which number holds what.

**7. Split into left and right panes:**

```text
prefix %
```

The current window splits down the middle into two panes — editor on the left, logs on the right, both alive at once.

**8. Split into top and bottom panes:**

```text
prefix "
```

Same thing, stacked horizontally. Yes, the mnemonics are backwards from what the symbols look like. No, nobody remembers which is which on the first day. You will after about a week, and until then you can guess and undo.

**9. Move between panes:**

```text
prefix o     (cycle to the next pane)
```

`o` walks you to the next pane in the window. Once you turn on mouse mode (next section), you can also click the pane you want — but `prefix o` works with zero config, which is why it's in the survival nine.

## The .tmux.conf that makes the defaults bearable

The defaults are usable but hostile. Four lines fix the worst of it. Put these in `~/.tmux.conf`:

```tmux
# Make the prefix less of a finger pretzel
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse: scroll, click a pane to select it, drag a border to resize
set -g mouse on

# Count windows from 1 — the key you press to reach window 1 is "1", not "0"
set -g base-index 1

# Reload this file without restarting tmux
bind r source-file ~/.tmux.conf \; display "reloaded"
```

`C-a` (Ctrl-a) is a far easier prefix to hit a hundred times a day than `C-b`. Mouse mode means scrolling and pane-selection do what your hand expects. `base-index 1` lines the window numbers up with the number keys you actually press. And `prefix r` reloads the config so you can tweak it without killing your sessions.

## You'll know it worked

Start a fresh session so it picks up the config, then check the three settings landed:

```bash
tmux kill-server      # clears any old server still running the defaults
tmux new -s test
```

Now, inside that session:

```text
prefix r
```

If the status bar flashes `reloaded`, your prefix is working (you used it a second ago) **and** the config loaded. To confirm the rest, from a shell:

```bash
tmux show-options -g prefix
tmux show-options -g mouse
tmux show-options -g base-index
```

```text
prefix C-a
mouse on
base-index 1
```

If you instead see `prefix C-b` or `base-index 0`, tmux didn't read the file — check it's actually at `~/.tmux.conf` (the dot matters) and start a fresh session, because running sessions keep the settings they were born with.

## When this goes wrong

**`tmux ls` says `no server running`.** That's not an error so much as a status: nothing is currently alive.

```bash
tmux ls
# no server running on /tmp/tmux-1001/default
```

You either haven't started a session yet, or your last one ended. Run `tmux new -s work` and you're back in business.

**`tmux attach` says `no sessions`.** The server is up but the name you asked for is gone (or you typo'd it):

```bash
tmux attach -t wrok
# no sessions
```

Run `tmux ls` to see the real names, then attach to one that exists.

**You pressed the prefix and nothing happened.** You probably let go of the gap. The rhythm is *press-and-release the prefix, then press the second key* — not all three at once. `Ctrl-a` then `c`, not `Ctrl-a-c` held down together.

**The big one: nesting tmux inside tmux.** SSH into a server that's also running tmux, attach there, and now your prefix is ambiguous — does `prefix c` make a window on your machine or the remote one? It goes to whichever tmux catches the prefix first, which is rarely the one you meant. The fix, once you're nested, is to press the prefix *twice* (`Ctrl-a` `Ctrl-a` `c`) to send it through to the inner session. Better: detach from the local one first. Either way, when your windows start landing in the wrong place, nesting is almost always why.

## The tally

```text
commands to survive a dropped connection:   9
config lines to make them bearable:         4
times you will wish you'd learned this:     every prior outage
```

Nine commands is not mastery. tmux can do session scripting, custom layouts, copy-mode with vim keys, status-bar plugins that show your CPU temperature. You can learn all of that later, or never.

But the nine above are the difference between *the build kept running* and *the build died with my SSH session and I have to start over*. That's the whole pitch. Everything else tmux does is a bonus on top of not losing your work.
