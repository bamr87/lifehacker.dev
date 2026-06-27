---
title: "Fork, build, and run a VS Code extension locally: the Front Matter dev-environment playbook"
description: "Fork the Front Matter extension, run the right dev build, and launch with F5 — plus the fake script name and extension collision that eat an afternoon."
date: 2025-08-27
collection: hacks
author: amr
excerpt: "Get the Front Matter extension building and reloading on your machine — and find out why the guide's npm run dev:ext does nothing and your dev copy fights the one you already installed."
tags: [vscode-extension, typescript, webpack, open-source, front-matter]
---

You want to fix one annoying thing in a VS Code extension. Not rewrite it, not become a maintainer — change a label, see it work, send a pull request. The README makes this sound like a weekend. It is closer to an afternoon, and most of that afternoon is spent on two things nobody writes down: the dev build command is not the one you guess, and your shiny dev copy quietly fights the published extension you already have installed.

We are going to do this with [Front Matter](https://github.com/estruyf/vscode-front-matter), a markdown CMS that lives inside the editor. The steps are the same for almost any TypeScript VS Code extension, so the muscle memory transfers. Every command below was either run on this machine or read straight out of the upstream repo — where it is the second kind, it says so.

## Fork, clone, point at upstream

Forking and cloning need the network and your GitHub account, so run these on your own machine — this is the documentation, not a captured session:

```bash
# Fork via the GitHub UI first: github.com/estruyf/vscode-front-matter → "Fork".
git clone https://github.com/YOUR_USERNAME/vscode-front-matter.git
cd vscode-front-matter
git remote add upstream https://github.com/estruyf/vscode-front-matter.git
```

The `upstream` remote is the part people skip and regret. `origin` is your fork; `upstream` is the original. Without it you have no way to pull in the maintainer's changes later, and your fork rots within a month.

The remote wiring itself is plain git, so we proved that part offline — two bare repos standing in for "the original" and "your fork", cloned and wired exactly the way the real ones are. The output is real:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir upstream.git fork.git
git init -q --bare upstream.git
git init -q --bare fork.git

# Seed "upstream" with one commit, then copy it to "fork" — what the Fork button does.
seed="$(mktemp -d)"
git -C "$seed" init -q
git -C "$seed" config user.email a@b.c
git -C "$seed" config user.name dev
echo "vscode-front-matter" > "$seed/README.md"
git -C "$seed" add . && git -C "$seed" commit -q -m seed
git -C "$seed" branch -M main
git -C "$seed" push -q "$PWD/upstream.git" main
git -C "$seed" push -q "$PWD/fork.git" main

# Now the developer clones THEIR fork, then adds upstream.
git clone -q "$PWD/fork.git" vscode-front-matter
cd vscode-front-matter
git remote add upstream ../upstream.git

git remote -v | sed "s#$(dirname "$PWD")#/path/to#g"
```

Real output:

```text
origin    /path/to/fork.git (fetch)
origin    /path/to/fork.git (push)
upstream  ../upstream.git (fetch)
upstream  ../upstream.git (push)
```

You'll know it worked when `git remote -v` shows **two** names: `origin` pointing at your fork, `upstream` at the maintainer's repo. If you only see `origin`, the `git remote add upstream` line did not run — scroll up and run it again.

## Install dependencies

This pulls hundreds of packages off npm, so it needs the network — documentation, not a sandbox run:

```bash
npm install
```

Front Matter's `package.json` declares `"engines": { "vscode": "^1.90.0" }`, which means a current-ish VS Code. A modern Node (18+) is fine. You'll know `npm install` worked when it exits without red `ERESOLVE` lines and a `node_modules/` folder appears next to `package.json`. If it dies on peer-dependency conflicts, your Node is probably ancient — check `node --version` before you start `npm`-bisecting anything.

## The part where it broke: the dev command isn't `dev:ext`

Here is the failure, left in, because every secondhand guide to this extension gets it wrong — including the one this post was rewritten from.

Those guides tell you to run `npm run dev:ext` to start the watch build. Do that and you get:

```text
npm error Missing script: "dev:ext"
npm error
npm error To see a list of scripts, run:
npm error   npm run
```

There is no `dev:ext`. It was never a real script; it got copied between blog posts until it looked official. The actual script — read straight out of the upstream `package.json` — is `dev`:

```bash
npm run dev
```

Which expands to:

```text
npm run clean && npm run localization:generate && npm-run-all --parallel watch:*
```

That one line does three real things: wipes `dist/`, regenerates the localization enum, then starts **three** parallel webpack watchers — `watch:ext` (the extension backend), `watch:dashboard` (the React dashboard, served on a dev port), and `watch:panel` (the sidebar webview). When you see all three compile and the process stays alive instead of returning to your prompt, the watch build is running.

When in doubt about *any* extension's scripts, don't trust the blog — ask the repo:

```bash
npm run
```

That prints every script `package.json` actually defines. If the command someone told you to run isn't in that list, it doesn't exist.

## Launch it with F5 — and the collision nobody warns you about

With `npm run dev` watching, open the project in VS Code and press `F5` (or open Run and Debug with `Cmd+Shift+D` and pick **Launch Extension**). A second VS Code window opens — the Extension Development Host — running your local build.

You'll know it worked when, in that new window, `Cmd+Shift+P` → typing "Front Matter" lists the extension's commands, and "Front Matter: Open dashboard" actually opens.

Here is the detail that costs the afternoon, and the source guide omitted it entirely. Front Matter is a *popular* extension — there is a very good chance you already have the published version installed. If your dev copy and the published copy both register the same commands, you get duplicate command-palette entries and no way to tell which one fired. Your code change appears to do nothing because the *installed* version is the one answering.

The upstream `.vscode/launch.json` already handles this. Its launch config passes:

```text
"args": [
  "--extensionDevelopmentPath=${workspaceFolder}",
  "--disable-extension=eliostruyf.vscode-front-matter"
],
"preLaunchTask": "npm: build:ext"
```

`--disable-extension=eliostruyf.vscode-front-matter` turns off the *published* extension inside the dev window, so only your local build is live. And `preLaunchTask: "npm: build:ext"` means F5 compiles before it launches — so even if you forgot `npm run dev`, the first F5 still produces a working `dist/`.

The catch: this only protects you if you launch via **F5 / the Launch Extension config**. If you start the dev host some other way — `code --extensionDevelopmentPath=.` by hand, say — you lose the `--disable-extension` flag and you are back to two extensions fighting over the same commands. Use the launch config. It is there for exactly this.

## The reload loop

Watch mode rebuilds when you save, but the running dev window does **not** pick up backend changes on its own. After editing extension code:

- In the Extension Development Host window, run `Cmd+Shift+P` → **Developer: Reload Window** (or `Cmd+R`).
- The dashboard and panel are React with hot-module reload, so *their* changes appear without a reload. Backend (`src/extension.ts`, commands, services) needs the reload.

You'll know your change took when the reloaded window shows the new behavior. If it doesn't, check the original VS Code window's terminal: a TypeScript error in the watcher means `dist/` never updated, so the dev host is still running the last good build. `console.log` from extension code shows up in the *original* window's Debug Console, not the dev host — that's the first place to look when something silently does nothing.

## When this goes wrong

A few honest failure modes, in the order you'll hit them:

- **`Missing script: "dev:ext"`** — you followed an old guide. Run `npm run dev`. (See above.)
- **Commands appear twice / your change has no effect** — the published extension is still active. Launch via F5 so `--disable-extension` applies, or disable the Marketplace copy by hand for that window.
- **Dashboard/panel port already in use** — a previous `npm run dev` is still alive. Find and kill it (`lsof -i :9000`, then `kill <PID>`), then restart `npm run dev`.
- **F5 launches but no Front Matter commands** — the build failed. Look at the watcher terminal in the original window for the TypeScript error; nothing reloads until it compiles.

## The honest accounting

None of this is hard once you know it. The trap is that the two things most likely to eat your afternoon — the script that doesn't exist and the extension fighting itself — are invisible. `npm run dev:ext` fails loudly enough to fix in a minute, but the duplicate-extension collision fails *silently*: your code looks broken when it's actually correct and merely being shadowed.

So: clone your fork, add `upstream`, run `npm run dev` (not `dev:ext`), and launch with F5 so the published copy steps aside. Then go change the label you came here to change.
