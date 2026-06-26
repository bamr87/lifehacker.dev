---
title: "It works on macOS, breaks in CI: bash 3.2 vs declare -A"
description: "Why your shell script passes locally and dies with 'command not found' (exit 127) in CI, and the version-detect-and-fall-back pattern that fixes it for real."
date: 2025-07-09
collection: hacks
author: amr
excerpt: "macOS still ships bash 3.2. CI runs bash 5. The gap is associative arrays — here's the failure and the fallback, both run for real."
tags: [bash, ci, github-actions, shell, compatibility]
---

The script ran fine on my laptop. It ran fine on the reviewer's laptop. Then CI ran it and printed this:

```console
./scripts/analyze-repository-health.sh: line 53: validate_argument: command not found
##[error]Process completed with exit code 127.
```

`command not found` for a function that is right there in the file. Exit 127, the code shells reserve for "I have no idea what you're asking me to run." The function exists. The file is sourced. And yet.

![A retro terminal showing a bash command-not-found error from a GitHub Actions run](/assets/images/previews/fixing-github-actions-bash-3-2-compatibility-for-a.png)

The plot twist is the direction of the bug. Everyone assumes CI has the old, busted environment and the laptop has the new shiny one. With bash, it is the reverse. CI (Ubuntu, Debian) ships bash 5. macOS ships **bash 3.2** — frozen in 2007, because every version since is GPLv3 and Apple won't ship it. So the script that "works on my machine" works *because* your machine is the old one.

## Confirm which bash you actually have

This is on a current macOS host. The `bash` Apple puts in your `$PATH` is this:

```console
$ /bin/bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
Copyright (C) 2007 Free Software Foundation, Inc.
```

That is real output, captured moments ago. `arm64-apple-darwin25` is a 2025 Mac. The bash on it is from 2007. (If you `brew install bash` you get 5.x, but it lands at `/opt/homebrew/bin/bash` — `#!/bin/bash` scripts still grab the 3.2 one.)

You'll know which one a script will use when `head -1 yourscript.sh` says `#!/bin/bash` and `/bin/bash --version` says 3.2. That combination is the trap.

## The thing that breaks: declare -A

Associative arrays — `declare -A` — landed in bash **4.0**. The health script used one to hold its validation rules:

```bash
declare -A VALIDATION_RULES=(
    [required]="not_empty"
    [string]="is_string"
)
```

Watch what bash 3.2 does with that. This is run for real on the same host:

```console
$ /bin/bash -c 'declare -A RULES=([required]="not_empty"); echo "${RULES[required]}"'
/bin/bash: line 0: declare: -A: invalid option
declare: usage: declare [-afFirtx] [-p] [name[=value] ...]
```

`-A: invalid option`. bash 3.2 has never heard of associative arrays. And here is the part that turns a clear error into a two-hour debugging session: **bash kept going.** It printed the error, the `declare` failed, but the script did not stop.

So later, when something called `validate_argument` — a function defined only *inside* the block guarded by that array — the function was never there, and you get the misdirection from the top of this post:

```console
$ /bin/bash demo_cmd_not_found.sh
demo_cmd_not_found.sh: line 4: validate_argument: command not found
exit code: 127
```

The error blames a missing function. The actual cause is a `declare -A` three screens up that quietly no-op'd.

## Detect the version, then branch

The fix is not "rewrite everything for bash 3.2." It is: ask which bash you're in, use the nice feature when you can, fall back when you can't.

Here is the detection. Real output, same host:

```console
$ BASH_VERSION_MAJOR=$(/bin/bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
$ echo "major = $BASH_VERSION_MAJOR"
major = 3
```

(There's also the built-in `$BASH_VERSION`, which on this host prints `3.2.57(1)-release` — fine for a human, but the parsed major number above is what you branch on.)

With that number in hand:

```bash
if [[ "${BASH_VERSION_MAJOR:-3}" -ge 4 ]]; then
    declare -A VALIDATION_RULES=(
        [required]="not_empty"
        [string]="is_string"
    )
    VALIDATION_USE_ARRAYS=true
else
    VALIDATION_USE_ARRAYS=false
fi
```

The `:-3` default matters: if the detection ever comes back empty, you assume the *old* bash and take the safe path. Failing toward compatibility, not toward the feature that crashes.

## The fallback that needs no arrays

When you can't have a key-value map, a `case` statement is one. It is uglier and it is portable to every bash that has ever existed. This block is self-contained — it builds its own data and uses only bash builtins — so it runs the same on bash 3.2 and bash 5:

```bash
# Portable validation: no associative arrays, no bash 4 features.
get_validation_rule() {
    case "$1" in
        required) echo "not_empty" ;;
        string)   echo "is_string" ;;
        integer)  echo "is_integer" ;;
        *)        echo "" ;;
    esac
}

validate_argument() {
    local name="$1" value="$2" allowed="$3"
    IFS='|' read -ra options <<< "$allowed"
    for opt in "${options[@]}"; do
        [ "$value" = "$opt" ] && return 0
    done
    echo "rejected: $name='$value' (allowed: $allowed)"
    return 1
}

echo "rule[required] = $(get_validation_rule required)"
echo "rule[bogus]    = '$(get_validation_rule bogus)'"
validate_argument intensity high "low|medium|high" && echo "accepted: high"
validate_argument intensity nuclear "low|medium|high"
```

You'll know it worked when you get the rule lookups and one accept/one reject, with no `declare` error in sight:

```console
rule[required] = not_empty
rule[bogus]    = ''
accepted: high
rejected: intensity='nuclear' (allowed: low|medium|high)
```

A `case` lookup replaces the map. A pipe-delimited string plus `read -ra` replaces the "is this value in the set" check. Same interface, same outputs, zero bash-4 features.

## The other two that bite

`declare -A` is the famous one, but bash 3.2 trips on two more that look innocent:

```bash
declare -g GLOBAL_VAR="value"   # -g (global from inside a function) is bash 4.2+
GLOBAL_VAR="value"              # portable: it's already global outside a function
```

And lowercasing a variable inline. This one is sneakier because it fails *differently* — run for real on the 3.2 host:

```console
$ /bin/bash -c 'value="HIGH"; echo "${value,,}"'
/bin/bash: ${value,,}: bad substitution
```

`${value,,}` (lowercase the whole value) is bash 4.0. In 3.2 it's a *syntax* error, not a runtime one. The portable version shells out to `tr`:

```console
$ /bin/bash -c 'value="HIGH"; echo "$value" | tr "[:upper:]" "[:lower:]"'
high
```

## The part where it broke (the catch that doesn't catch)

The obvious reflex is "I'll lint my scripts with `bash -n` before they ship." `bash -n` parses without executing. It catches some of these. It does **not** catch the worst one — and here's the proof, run on the 3.2 host:

```console
$ printf '#!/bin/bash\ndeclare -A x=([a]=1)\n' > synt.sh
$ /bin/bash -n synt.sh
$ echo "bash -n exit: $?"
bash -n exit: 0
```

Exit 0. Clean. `bash -n` says the script with `declare -A` is fine — because `declare -A` is *valid syntax*; it only blows up at runtime when 3.2's `declare` rejects the `-A` flag. Meanwhile `${value,,}` *is* a parse error, so `bash -n` would flag that one. Two bugs in the same family, and your syntax checker catches exactly one of them.

So `bash -n` is worth running, but it is not the safety net you think it is. The net that actually works is running the script under the old bash. If you're not on a Mac, a container gives you one:

```bash
# Run your script against real bash 3.2 (not run here — needs Docker + network)
docker run --rm -v "$(pwd):/work" -w /work bash:3.2 ./yourscript.sh
```

That block is documentation, not captured output — pulling an image needs network and Docker, which the things we run for real here don't have. But it is the honest test: execute under 3.2, see the failure your CI would see, before CI sees it.

## The honest accounting

The version-detect-and-branch pattern costs you a `case` statement where you wanted a hash map. It is more lines and slightly worse-looking code. What you buy is a script that stops lying to you — one that behaves the same on the 2007 bash Apple ships and the 2025 bash your CI runs, so "works on my machine" stops being a coin flip.

The rule, stated plainly: **if your script has a `#!/bin/bash` line, assume someone will run it on bash 3.2.** Detect the version, guard the bash-4 features, and run it under old bash at least once before you trust it. The bug that costs you the afternoon is never the loud one — it's the `declare -A` that printed an error nobody read and then kept going.
