---
title: "direnv: the env loader that hashes your .envrc and trusts everything it sources"
description: "direnv blocks a new or edited .envrc until you allow it. It does not check the files that .envrc sources. Threat-modeled and tested on 2.32.1."
date: 2026-10-29
preview: /images/previews/direnv-the-env-loader-that-hashes-your-envrc-and-t.svg
categories: [Tools]
tags: [system, productivity]
author: cass
verdict: "Use it. The allow gate is real and it held every time I hit it. But it covers one file: keep .envrc self-contained, never set whitelist.prefix, and keep secrets in a gitignored .envrc.local."
excerpt: "A tool that runs code every time you cd. It does ask first, and that check is real. The check covers exactly one file, and I spent an afternoon running code through the files next to it."
permalink: /tools/direnv-honest-review/
---
**Verdict: use it. `direnv` loads per-project environment variables when you `cd` into a directory and unloads them when you leave. It's the one shell hook I'd let near my prompt, because it refuses to run a new or edited `.envrc` until you say `direnv allow`, and that refusal held every time I tested it. The catch is that the gate checks one file. Everything that file *sources* gets through unchecked. Below are the five ways I got code to run without a prompt, and the three settings that close them.** I have no relationship with direnv or its maintainers. It's MIT-licensed, nobody paid me, and I read the license twice because free software that runs code on `cd` deserves a second read.

Think about what this tool is. A program wired into your prompt that runs a shell script every time you change directory. If a pentester pitched that design to me I'd ask which APT group they work for. The feature is "your environment configures itself." The attack surface is "a directory you cloned configures your shell." The difference between the two is a single hash check, so the hash check is what I tested.

Everything below ran for real on Ubuntu 24.04, `direnv 2.32.1` from apt, bash 5.2.21. Each test used a throwaway directory under `/tmp`, with `XDG_DATA_HOME` and `XDG_CONFIG_HOME` pointed at `/tmp/dd` so the allow-list was a sandbox too. Instead of an interactive hook I ran `eval "$(direnv export bash)"` by hand after each `cd`. That's the same call the hook makes before every prompt; I just made it where you can see it. Every "payload" is `touch /tmp/PWNED-something`. My attacker is fictional and shows no ambition.

## What earns the install

The gate. Drop an `.envrc` in a directory and direnv will not run it until you've seen it:

```console
$ cat .envrc
export API_TOKEN=sk-demo-1234
echo "hello from .envrc, I am $(whoami)" >&2
touch /tmp/proj/RAN

$ cd /tmp/proj
direnv: error /tmp/proj/.envrc is blocked. Run `direnv allow` to approve its content
$ echo "TOKEN=${API_TOKEN:-unset}"; ls RAN
TOKEN=unset
ls: cannot access 'RAN': No such file or directory

$ direnv allow .
direnv: loading /tmp/proj/.envrc
hello from .envrc, I am runner
direnv: export +API_TOKEN
```

Nothing ran until I allowed it, and the `touch` really didn't fire. Then the part that earns real trust: edit the file and it's blocked again, and the variables it set get unloaded:

```console
$ echo 'export EXTRA=1' >> .envrc
direnv: error /tmp/proj/.envrc is blocked. Run `direnv allow` to approve its content
$ echo "TOKEN=${API_TOKEN:-unset} EXTRA=${EXTRA:-unset}"
TOKEN=unset EXTRA=unset
```

The approval is a hash of the file's **path plus its contents**, stored as an empty-ish file under `~/.local/share/direnv/allow/`. Copy the same repo to `/tmp/proj2` and it's blocked there too. The approval doesn't travel. Leave the directory and everything unloads (`direnv: unloading`). So a malicious commit that edits `.envrc` lands on your next `cd` as a red error and doesn't run. `SEVERITY: low. ATTACK VECTOR: an attacker who needs you to read their diff and type "allow" anyway.`

Two small things I noticed. First, an edit made in the same wall-clock second as the last load wasn't noticed until the file's mtime changed again. The old variables stayed loaded and the new code didn't run, so it's stale but safe. Second, approvals stack up. I edited a file, then put back the exact old contents, and it loaded with no prompt, because the old hash was still on the list. `direnv deny .` (also spelled `revoke`, `block`) is how you take one back.

Now for the problem. Go back to "a hash of the file's contents." Which file?

## Leak #1: the gate checks .envrc, not what .envrc sources

Real-world `.envrc` files don't hold logic. They call out to the repo's own scripts, because that's what clean code looks like:

```console
$ cat .envrc
source ./scripts/setup.sh
$ direnv allow .
direnv: loading /tmp/proj/.envrc
direnv: export +GREETING
```

Now play the attacker, or the compromised dependency bot, or the coworker who "just tidied up the setup script." Leave `.envrc` alone. Edit only the helper:

```console
$ printf 'export GREETING=hi\ntouch /tmp/PWNED-helper\n' > scripts/setup.sh

$ cd / && cd /tmp/proj
direnv: unloading
direnv: loading /tmp/proj/.envrc
direnv: export +GREETING
$ ls /tmp/PWNED-helper
/tmp/PWNED-helper
```

No prompt, no red error. The approved file's hash didn't change, so as far as direnv knows nothing changed. It ran the new code on my next `cd`. The gate held; the attack just went around it.

The natural fix is `watch_file scripts/setup.sh`, which tells direnv to watch the helper too. It makes things worse. I tried it. `watch_file` means "reload when this changes," not "ask me again." With it in place, editing the helper re-ran it **right away on the next prompt**, still with no question asked:

```console
$ cat .envrc
watch_file scripts/setup.sh
source ./scripts/setup.sh
$ printf 'export GREETING=hi\ntouch /tmp/PWNED-watched\n' > scripts/setup.sh
direnv: loading /tmp/w/.envrc
direnv: export +GREETING
$ ls /tmp/PWNED-watched
/tmp/PWNED-watched
```

Picture the nation-state version: a three-letter agency spends eighteen months befriending your build-tooling maintainer just to land a one-line change in `scripts/setup.sh`. Back to reality: nobody needs that much effort. Any `git pull` that touches a sourced file is code you'll run on your next `cd`, with nothing to warn you. That's how `.envrc` works when it's a shell script, and it's also exactly what the allow gate looks like it protects you from. `RATING: CVE-YOUR-OWN-REFACTOR. EXPLOITABILITY: git pull.`

## Leak #2: source_up trusts every parent you never looked at

`source_up` is the stdlib helper that also loads the nearest `.envrc` in a parent directory. Monorepos love it. I put an `.envrc` in `/tmp/up` that I **never allowed**, and a child `.envrc` that calls `source_up`, and allowed only the child:

```console
$ cat /tmp/up/.envrc
export PARENT=1
touch /tmp/PWNED-parent
$ cat /tmp/up/child/.envrc
source_up
export CHILD=1

$ cd /tmp/up/child && direnv allow .
direnv: loading /tmp/up/child/.envrc
direnv: loading /tmp/up/.envrc
direnv: export +CHILD +PARENT
$ ls /tmp/PWNED-parent
/tmp/PWNED-parent
```

The parent file was never allowed and it ran anyway. Allowing a child that calls `source_up` means trusting every `.envrc` above it, now and after every future pull. Most of the time the parents are your own home directory and this is fine. In a monorepo where forty teams can edit the root `.envrc`, you've approved forty teams.

## Leak #3: whitelist.prefix is "allow everything" with a nicer name

direnv's config file (`~/.config/direnv/direnv.toml`) has a `[whitelist]` section, so people who get tired of typing `allow` can stop. This is where convenience gets an attack surface. I set it the way people do, to the folder they clone everything into:

```console
$ cat ~/.config/direnv/direnv.toml
[whitelist]
prefix = [ "/tmp/src" ]

$ cd /tmp/src/cloned-repo
direnv: loading /tmp/src/cloned-repo/.envrc
direnv: export +W
$ ls /tmp/PWNED-whitelist
/tmp/PWNED-whitelist
```

That's a repo I'd never opened, running code because of where I cloned it. With `prefix`, `git clone` plus `cd` becomes remote code execution, and you set it up yourself to save typing. `SEVERITY: whoever owns any repo you've ever cloned. ATTACK VECTOR: curiosity.`

The `[global] load_dotenv = true` setting, which makes direnv read plain `.env` files, does **not** get around the gate. A new `.env` was blocked like an `.envrc` (`direnv: error /tmp/ld/.env is blocked`). Credit where it's due.

## Leak #4: the secret you export rides along twice

Your `.envrc` exports `API_TOKEN`, so every child process of that shell gets it: `npm install`, every `postinstall` script in that dependency tree, the AI coding agent you started "just to look around." That's how environment variables work, and it isn't direnv's fault, but direnv makes it automatic and invisible:

```console
$ bash -c 'echo "child sees: $API_TOKEN"'
child sees: sk-demo-1234
```

Here's the part I didn't expect. direnv keeps its own bookkeeping in your environment (`DIRENV_DIR`, `DIRENV_FILE`, `DIRENV_WATCHES`, `DIRENV_DIFF`), and `DIRENV_DIFF` is a zlib-compressed, base64 JSON copy of what it changed. That includes the new value:

```console
$ env | grep -c sk-demo
1
$ python3 -c 'import os,base64,zlib,json; print(json.loads(zlib.decompress(base64.urlsafe_b64decode(os.environ["DIRENV_DIFF"])))["n"]["API_TOKEN"])'
sk-demo-1234
```

`grep` finds one copy. There are two. If your CI log scrubber or "redact secrets from env dumps" script matches on the plain value, it misses the compressed one. It's harmless until something dumps the environment into a bug report.

## Leak #5, the small one: .env parsing fails closed

This one's reassuring. I tried to sneak a command into a `.env` loaded with `dotenv`. An unquoted `X=$(touch /tmp/PWNED-dotenv)` is rejected with `direnv: error invalid line`, and **the whole file loads nothing**. `FOO=bar` on the line above it was dropped too. Quoted, `X="$(touch …)"` comes through as a literal string, while `"${HOME}/x"` *does* expand to `/home/runner/x`. No code ran either way. Just know that one bad line silently empties the whole file instead of loading the rest.

## The three mitigations, ranked

Each one I actually ran in the sandbox above.

**1. Keep `.envrc` self-contained: the hash covers only what's in the file.** Put the logic you'd have sourced inline, so any change to it changes the hash and blocks with `direnv: error … is blocked` (tested above: one appended line blocked and unloaded everything). Don't add `source ./scripts/whatever.sh`, and don't use `watch_file` as a security fix, because it reloads without asking. If a repo you didn't write uses `source_up` or sources helpers, read those files too before typing `allow`, and again after every pull. The gate only checks the file it can see.

**2. Never set `whitelist.prefix`.** Check that it's empty:

```console
$ direnv status | grep -i whitelist
whitelist.prefix []
whitelist.exact map[]
```

If you really can't stand typing `allow` for your own dotfiles repo, use `whitelist.exact` with the full path of that one `.envrc`, never a parent folder you clone strangers' code into.

**3. Secrets go in a gitignored `.envrc.local`, not the committed `.envrc`.** The committed file loads it with a stdlib helper, and git confirms it will never be committed:

```console
$ cat .envrc
export APP_ENV=dev
source_env_if_exists .envrc.local
$ cat .gitignore
.envrc.local
$ git check-ignore -v .envrc.local
.gitignore:1:.envrc.local	.envrc.local

$ direnv allow .
direnv: loading /tmp/m/.envrc
direnv: loading /tmp/m/.envrc.local
direnv: export +API_TOKEN +APP_ENV
```

Yes, this is the same unchecked-`source` pattern as Leak #1, used on purpose. It's safe here only because `.envrc.local` is a file you write and no `git pull` can touch. And remember Leak #4: whatever it exports, every child process inherits, twice. When you're done with a project, `direnv deny .` unloads it and takes back the approval (`TOKEN=unset` afterwards, tested).

## Bottom line

direnv is the rare convenience tool that did think about security. The allow gate is real: path-plus-content hashed, re-checked on every edit, never carried to a copy. It blocked everything I aimed straight at it. Everything that got through went *around* it: through a sourced helper, a `source_up` parent, or a whitelist I set up myself. Keep the trusted code in the one file it hashes, keep the whitelist empty, and keep the secrets out of git, and it's the safest way I know to have your shell configure itself. Docs and stdlib reference: [direnv.net](https://direnv.net/).
