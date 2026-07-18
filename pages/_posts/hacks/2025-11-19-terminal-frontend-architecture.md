---
title: "Wrap your scary shell scripts in Gum: a three-layer 'glass interface'"
description: "Put a menu over deploy.sh with gum, but keep the logic non-interactive so it still runs in CI — plus the read prompt that silently deploys to nowhere."
date: 2025-11-19
categories: [Hacks]
tags: [shell, ci-cd]
author: amr
excerpt: "A gum menu makes deploy.sh hard to fat-finger. The trick is keeping the dangerous part underneath answerable by a robot, not a human."
preview: /images/previews/section-hacks.svg
permalink: /hacks/terminal-frontend-architecture/
---
The pitch for putting a pretty menu over your shell scripts is that it stops people from running `./deploy.sh -f -e prod` when they meant `-e prod -f` and nuking the wrong environment. That part is true. The pitch usually stops there, right before the part that actually matters: if you bake the menu *into* the script, you can never run that script from CI again, because there's nobody there to answer the menu.

So this is two things at once. A `gum` frontend that's nice to use, and a rule about where the frontend is allowed to live so you don't trade a typo problem for an "it hangs in the pipeline" problem. The rule is the whole hack. The menu is decoration.

## The one idea: split the *asking* from the *doing*

Three layers, but really two jobs:

1. **Core logic** — takes arguments, asks nothing, returns an exit code. This is
   the part that touches production.
2. **The frontend** — asks the human questions, validates the answers, then
   calls the core with those answers as arguments.

The core never knows whether a human or a cron job filled in its arguments. That single property is what lets the same `deploy_app prod v1.4.2` run behind a friendly menu *and* unattended in CI. Mix the two and you lose it.

Here's the core, by itself, run for real (no gum required to prove the point):

```bash
# lh:run
cat > deploy.sh <<'EOF'
#!/usr/bin/env bash
# Core logic. Takes arguments. Asks NOTHING. Returns an exit code.
deploy_app() {
  local env=$1 version=$2
  [ -n "$env" ]     || { echo "deploy_app: missing env" >&2; return 2; }
  [ -n "$version" ] || { echo "deploy_app: missing version" >&2; return 2; }
  echo "deploying $version to $env"
  # the real work goes here: kubectl / aws / rsync ...
}
EOF

# Call it the way CI would — no human, no prompt:
bash -c 'source ./deploy.sh; deploy_app prod v1.4.2; echo "exit=$?"'
echo "--- forget an argument and it refuses, loudly ---"
bash -c 'source ./deploy.sh; deploy_app prod; echo "exit=$?"'
```

Real output:

```console
deploying v1.4.2 to prod
exit=0
--- forget an argument and it refuses, loudly ---
deploy_app: missing version
exit=2
```

**You'll know it worked when** the happy path prints its line and exits `0`, and the missing-argument path prints to *stderr* and exits non-zero. That non-zero is the contract: a pipeline can check `$?` and stop. A menu can never give you that.

## The frontend, with Gum

[Gum](https://github.com/charmbracelet/gum) is a single binary from Charm that gives you menus, text inputs, confirmations, and spinners as plain commands you capture with `$(...)`. Install it from its releases page or your package manager (`brew install gum`, `apt`, etc.).

The frontend wraps the *same* `deploy_app` from above. It collects answers, it refuses to proceed on a bad one, and only then does it call the core:

```bash
#!/usr/bin/env bash
source ./deploy.sh   # the non-interactive core from above

# 1. Ask (constrained choices — no free-typing "prdo")
env=$(gum choose dev stage prod)

# 2. Ask (free text, but we validate it ourselves next)
version=$(gum input --placeholder "v1.0.0")

# 3. Validate in the frontend, NOT in the core
if [ -z "$version" ]; then
  gum style --foreground 196 "version is required"
  exit 1
fi

# 4. Make 'yes' to production deliberate
if [ "$env" = "prod" ]; then
  gum confirm "deploy to PRODUCTION?" || exit 1
fi

# 5. Hand the answers to the core as arguments
deploy_app "$env" "$version"
```

`gum choose dev stage prod` can only return one of those three strings, so the "was it prod or prdo" class of typo stops existing. `gum confirm` exits non-zero
on "no", and the `|| exit 1` turns that into a clean bail-out. Notice the core
function did not change one character — the menu only fills in its arguments.

**You'll know it worked when** picking `prod` makes you confirm, and the deploy line that prints is the same one the bare `deploy_app prod v1.4.2` printed above.

## The part where it broke (twice)

This is the actual lesson, and it's the thing the tidy three-layer diagram skips.

### Break 1: a `read` inside the core silently deploys to nowhere

The tempting shortcut is to put the prompt *in* the function — "it's one `read`, what's the harm." The harm is that CI has no terminal. People assume an unanswered `read` will hang the pipeline, which would at least be visible. It's worse than that: with stdin coming from `/dev/null`, `read` returns immediately with an *empty* variable, and the script sails on. Run for real:

```bash
# lh:run
cat > bad.sh <<'EOF'
#!/usr/bin/env bash
deploy_app() {
  read -rp "Deploy to which env? " env   # interface baked into logic
  echo "deploying to '$env'"
}
EOF

echo "=== the way CI runs it: no terminal on stdin ==="
bash -c 'source ./bad.sh; deploy_app' < /dev/null
echo "exit=$?"
```

```console
=== the way CI runs it: no terminal on stdin ===
deploying to ''
exit=0
```

It deployed to `''` and reported success. No hang, no error, no clue — only a broken deploy with a green checkmark. That is exactly the outcome the asking/doing split exists to prevent: the core can't ask questions, so it can't get an empty answer it doesn't notice.

### Break 2: `gum spin` can't see your shell functions

The other trap is reaching for `gum spin` to put a spinner over the work:

```bash
gum spin --title "Deploying..." -- deploy_app "$env" "$version"
```

This looks right and fails quietly, because `gum spin` runs its command in a *separate process* — it's a binary spawning a child, not your shell. Your `deploy_app` is a shell function that exists only inside the current shell, so the child can't find it. `gum spin` runs an external program; a function isn't one. (You'll also see broken examples floating around with a stray second `--` and a `show_output=false` token — gum's flag is `--show-output`, and anything after the `--` is the command to run, not an option.)

If you want a spinner, spin a real command — `gum spin --title "Deploying…" -- ./deploy.sh prod v1.4.2`, where `deploy.sh` runs the deploy when executed directly — or skip the spinner entirely and let the deploy print its own progress. A function stays callable directly; that's the property worth keeping.

## When this goes wrong

- **`gum: command not found`** — it's a single binary, not a bash builtin.
Install it (`brew install gum` / your package manager / the GitHub releases page) before sourcing any frontend that calls it.
- **The pipeline run "succeeds" but nothing deployed.** Something interactive
leaked into the code path CI takes — a `read`, a `gum input`, a `gum confirm`. Grep the core for those and move every one of them up into the frontend.
- **`gum spin` "runs" but your function never executes.** It can't call shell
  functions. Point it at a real executable, or drop the spinner.
- **`gum choose` returns nothing and the script proceeds anyway.** The user hit
`Esc`. Treat an empty pick like a failed validation and `exit 1`, the same way the `version` check above does.

## Level up

This hack lives next to a longer build-it-yourself quest on IT-Journey, where you forge the same glass interface as a guided exercise: [Terminal Artificer: Forging the Glass Interface](https://it-journey.dev/quests/0010/side-quests/terminal-artificer/).

The whole thing reduces to one sentence you can tape to your monitor: **the menu asks, the function does, and the function never asks.** Keep that line and the same script works for the human at 2pm and the robot at 2am.
