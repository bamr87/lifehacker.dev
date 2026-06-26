---
title: "Stop copy-pasting bash logging: a sourced lib with a reload guard"
description: "Extract repeated bash logging into one sourced log.sh, fix the readonly crash when two scripts source it, and skip color codes when output isn't a terminal."
date: 2025-07-05
collection: hacks
author: amr
excerpt: "One log.sh, sourced everywhere — plus the readonly crash that happens the second two files pull it in, and the four-line guard that stops it."
tags: [bash, shell, logging, ci]
---

Every shell script you write starts the same way. You paste the color codes. You paste the little `log()` function that does the `[INFO]` and `[ERROR]` prefixes. You change one of them three weeks later and now twenty scripts disagree about what red means.

The fix is the oldest one in computing: write it once, put it in a file, and have every other script `source` that file. The catch is that "have every script source it" turns into "have it sourced twice," and the second source is where bash crashes in a way that takes a while to understand.

So this is two things: a small logging library worth copying, and the four-line guard that keeps it from blowing up when it gets loaded more than once.

## The library

Here is `log.sh`. It is deliberately tiny — two functions and a block that figures out whether to emit color. The rule that earns its keep is at the very top.

```bash
# log.sh — a tiny logging library, meant to be sourced.

# Reload guard: if this file is already loaded, stop right here.
if [ -n "${LOG_SH_LOADED:-}" ]; then
  return 0
fi
LOG_SH_LOADED=1

# No TTY (a CI runner, a pipe) -> no color. A terminal -> color.
if [ -t 1 ]; then
  C_INFO=$'\033[0;34m'; C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'
else
  C_INFO=''; C_ERR=''; C_OFF=''
fi

log_info()  { printf '%s[INFO]%s  %s\n' "$C_INFO" "$C_OFF" "$*"; }
log_error() { printf '%s[ERROR]%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; }
```

Two details that aren't decoration. `log_error` writes to `>&2` so your errors land on stderr where errors belong — they survive `script.sh > out.log` and still show up. And the color check is `[ -t 1 ]`, "is stdout a terminal," so the escape codes vanish the moment output goes to a pipe or a CI log instead of painting `\033[0;31m` all over your build output.

Any script that wants logging now starts with one line instead of twenty:

```bash
source "$(dirname "$0")/log.sh"

log_info "deploy started"
```

You'll know it worked when `log_info hello` prints `[INFO]  hello` in a terminal, and the same line with no escape junk when you pipe it through `cat`.

## The part where it broke

Here is the failure, because it is the entire reason the guard exists.

Real scripts don't source `log.sh` once. Script A sources it. Script A also sources `db.sh`, and `db.sh` — wanting to log things too — sources `log.sh` as well. Now `log.sh` runs twice in the same shell. The first time is fine. The second time, if the library declared anything `readonly`, bash refuses.

This is the naive library that triggers it — note the `readonly`, which is a reasonable instinct (the prefix should be a constant) and also the trap:

```bash
# A naive logging lib with NO reload guard, marking its config readonly.
lib="$(mktemp)"
cat > "$lib" <<'LIB'
readonly LOG_PREFIX="[app]"
log_info() { printf '%s [INFO] %s\n' "$LOG_PREFIX" "$*"; }
LIB

# Source it twice (as two libraries each pulling it in would). Capture the
# stderr from the second source so we can show it with a stable path.
err="$(mktemp)"
. "$lib"
. "$lib" 2>"$err"
sed "s#$lib#log.sh#" "$err"

log_info "did we even get here?"
rm -f "$lib" "$err"
```

We ran that. The real output:

```
log.sh: line 1: LOG_PREFIX: readonly variable
[app] [INFO] did we even get here?
```

There's the message: `LOG_PREFIX: readonly variable`. The second `source` hit `readonly LOG_PREFIX` while `LOG_PREFIX` was already readonly from the first source, and bash printed an error to stderr. (We collapsed the temp path to `log.sh` with `sed` so the line reads cleanly; the real path is whatever `mktemp` handed us.)

The cruel part is the line after it: `[app] [INFO] did we even get here?`. The script *kept going*. A `readonly` reassignment is an error, not a fatal one, so a plain `source` shrugs and continues. Your logging still works, there's a scary red line in the output, and nothing actually stopped — which is exactly the kind of error people learn to scroll past. Then you add `set -e` somewhere upstream, the same reassignment becomes fatal, and the script that worked yesterday dies on a line that hasn't changed.

## The guard

The fix is the four lines at the top of the real library: a plain variable that records "I have been loaded," and a `return` that bails out before any of the `readonly` declarations run a second time.

```bash
if [ -n "${LOG_SH_LOADED:-}" ]; then
  return 0
fi
LOG_SH_LOADED=1
```

`LOG_SH_LOADED` is **not** readonly — it's the one thing in the file that has to survive being set twice. The `${LOG_SH_LOADED:-}` is the careful bit: under `set -u` an unset variable is itself an error, so the `:-` gives it an empty default on the first pass. First source: the variable is empty, the `if` is false, the file runs and sets the flag. Every source after that: the flag is set, `return 0` fires, and the file does nothing.

`return` works here only because the file is *sourced*, not executed — `return` outside a function is legal inside a sourced file and illegal in a script you run directly. That's the right behavior: a library that someone runs as `./log.sh` instead of sourcing should complain.

Here is the guarded library proving it, sourced twice on purpose:

```bash
# --- write the logging lib to a temp file -------------------------------
lib="$(mktemp)"
cat > "$lib" <<'LIB'
# log.sh — a tiny logging library, meant to be sourced.

# Reload guard: if this file is already loaded, stop right here.
if [ -n "${LOG_SH_LOADED:-}" ]; then
  return 0
fi
LOG_SH_LOADED=1

log_info()  { printf '[INFO]  %s\n' "$*"; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

echo "log.sh: sourced (this line runs once)"
LIB

# --- source it twice; the guard makes the second a no-op ----------------
. "$lib"
. "$lib"

log_info "deploy started"
log_error "deploy failed, rolling back"

rm -f "$lib"
```

We ran that. The real output:

```
log.sh: sourced (this line runs once)
[INFO]  deploy started
[ERROR] deploy failed, rolling back
```

`log.sh: sourced (this line runs once)` prints exactly once even though we sourced the file twice — that line is the proof the guard fired on the second pass. No `readonly` error, because the second source returned before it reached anything. (The `[INFO]` block here has no color because the sandbox runs it through a pipe, not a terminal — that's the `[ -t 1 ]` check from the real library doing its job.)

## When this still goes wrong

The guard is per-shell, not per-machine. It uses a normal shell variable, so it only suppresses re-sourcing **within the same shell process**. Open a new terminal, or run a subshell with `bash other.sh`, and the variable is gone — that fresh shell sources `log.sh` from scratch, which is what you want. Don't expect the guard to remember anything across processes; it isn't a cache.

Two more things that bite:

Pick a flag name nobody else uses. `LOADED` will eventually collide with some other library's `LOADED`, and then sourcing library B silently skips library A because A's guard saw B's flag. Name it after the file — `LOG_SH_LOADED`, `DB_SH_LOADED` — and the collision goes away.

And `return 0` only short-circuits a `source`. If something later in your pipeline pipes the library into a subshell (`cat log.sh | bash`), the `return` runs in a context where it's meaningless and the guard does nothing. Source files. Don't pipe them.

The whole hack is four lines and one habit: every library you intend to source gets a uniquely-named `LOADED` guard at the top, and the one thing in the file that isn't `readonly` is that flag. Do that once and "sourced twice" stops being a crash and goes back to being a no-op, which is what it should have been the whole time.
