---
title: "jq's // default silently eats your false values"
description: "jq's // operator treats false like a missing key, so backup_files: false flips back to true. Here's the repro and two fixes that respect a real false."
date: 2025-07-05
collection: hacks
author: amr
excerpt: "You set backup_files to false. jq read it back as true. The // operator is the culprit, and the fix is one line."
tags: [jq, json, bash, config]
---

![A retro control panel illustrating an automated version-management pipeline](/assets/images/previews/advanced-version-management-system-complete-implem.png)

You wrote `false` in a config file. You wrote it on purpose. You read it back with `jq` and it came out `true`.

This is not a typo and you are not losing your mind. It is the `//` operator doing exactly what it was designed to do, which happens to be the opposite of what you wanted.

The setup: a `.version-config.json` had a `backup_files: false` switch to stop a script from littering the repo with `.version-backup` files. The switch was set. The script ignored it and made the backups anyway. The bug was one character of jq.

## The line that lied

The original config read looked sensible:

```bash
backup_enabled=$(jq -r '.change_tracking.backup_files // true' "$VERSION_CONFIG")
```

The reasoning behind it is reasonable too: "read `backup_files`, and if it's not there, default to `true`." The `//` is jq's alternative operator, the same shape as `||` in a lot of languages. You reach for it the second you want a fallback.

The problem is what jq decides counts as "not there."

## You'll know it broke when false comes back true

jq's `//` doesn't fall back only on missing keys. It falls back on any value that is `null` **or `false`**. To jq, a literal `false` and an absent key are the same thing, and both get replaced by the default.

Here is the whole bug in one self-contained block. The config says backups are off; watch jq turn them back on.

```bash
# A config that explicitly disables backups.
cfg='{"change_tracking":{"backup_files":false}}'

echo "raw value in the config:"
echo "$cfg" | jq -r '.change_tracking.backup_files'

echo "value after the // true fallback:"
echo "$cfg" | jq -r '.change_tracking.backup_files // true'
```

We ran that. The real output:

```
raw value in the config:
false
value after the // true fallback:
true
```

The raw value is `false`. Run it through `// true` and it becomes `true`. The script read "make backups: true," and made the backups, and the config that said otherwise was overruled by an operator that couldn't tell `false` apart from missing.

## Why it does this

`//` was built for the common case: "give me `.x`, or this default if `.x` is null or false." That second half is the trap. In JSON, `false` is a real, intentional value — it is the entire point of a boolean. But to `//`, false is one more flavor of empty, indistinguishable from a key that was never set.

So `//` is the right tool for "string that might be blank" and the wrong tool for "boolean that might be false." The moment your default lives on the opposite side of a boolean from your real value, `//` will eat the value you cared about.

## Fix one: read the raw value, default only on null

Stop asking jq to decide what's missing. Read the value exactly as written, then handle a genuinely-absent key yourself in bash, where you can check for `null` without lumping `false` in with it.

```bash
read_bool() {
  local cfg="$1" val
  val=$(echo "$cfg" | jq -r '.change_tracking.backup_files')
  [ "$val" = "null" ] && val=true   # default ONLY when truly absent
  echo "$val"
}

echo "explicit false -> $(read_bool '{"change_tracking":{"backup_files":false}}')"
echo "key missing    -> $(read_bool '{"change_tracking":{}}')"
```

We ran that. The real output:

```
explicit false -> false
key missing    -> true
```

`false` survives as `false`. A missing key still gets the `true` default. The distinction `//` flattened is now intact, because `jq -r` on a missing key prints the literal string `null`, and that — not `false` — is what we test for.

## Fix two: keep it in jq with an explicit null check

If you'd rather not bounce through a bash variable, say what you actually mean inside jq: default *only* when the value is `null`, leave `false` alone.

```bash
check() {
  echo "$1" | jq -r '.change_tracking.backup_files
                      | if . == null then true else . end'
}

echo "explicit false -> $(check '{"change_tracking":{"backup_files":false}}')"
echo "key missing    -> $(check '{"change_tracking":{}}')"
```

We ran that. The real output:

```
explicit false -> false
key missing    -> true
```

Same correct result, one process instead of post-processing in the shell. The `if . == null` is the whole fix: it tests for the one condition you meant — *absent* — instead of `//`'s broader *absent-or-false*.

## The part where it broke, stated plainly

The `// default` operator in jq falls back on `null` **and** `false`. If the value you're reading is a boolean that can legitimately be `false`, `//` will silently replace your `false` with the default, and nothing will warn you — the script quietly does the thing you turned off.

It cost an afternoon of "why are these backup files still here, the config clearly says false," because the config *did* say false and the parser *did* read false and then threw it away one character later.

The rule worth taping to your monitor: **`//` is for strings and missing keys, not for booleans.** The second your fallback sits on the far side of a boolean from a real value, reach for an explicit `== null` check instead. It's one more line and it's the difference between a config switch that works and a config switch that's decorative.
