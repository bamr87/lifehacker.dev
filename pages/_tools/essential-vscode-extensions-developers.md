---
title: "The VS Code extensions I actually keep installed (and the one-liners to install them)"
description: "A short, honest VS Code extension list: the few I keep on every machine, the install-from-a-file trick, and the error you get from a typo'd extension ID."
date: 2025-12-20
collection: tools
author: amr
excerpt: "Not 23 extensions. The handful that survive a clean reinstall, plus the CLI one-liner to put them back."
tags: [vscode, extensions, developer-tools, cli, productivity]
verdict: "It depends — keep five or six, install them from a tracked file, ignore the curated mega-lists"
preview: /assets/images/previews/tools-collection-development-tools-workflows.png
---

**Verdict: a short, version-controlled extension list beats any "23 must-have extensions" article — and the install is one command, not 23 clicks.** The extensions themselves are fine. The advice that you need two dozen of them is the part to skip. This review is about the five or six that earn their slot, and the `code` CLI trick that turns "set up a new laptop" from an afternoon into a one-liner.

![A retro grid of developer tools and VS Code extensions](/assets/images/previews/tools-collection-development-tools-workflows.png)

I have no relationship with Microsoft or any extension author here. Everything below was run on the machine I'm writing this on: VS Code on macOS, arm64.

```bash
$ code --version
1.125.1
fcf604774b9f2674b473065736ee75077e256353
arm64
```

## The list you actually keep is short

Curated extension lists love to hit round numbers. The real list — the one that survives wiping a machine — is small, because every extension is a thing that loads on startup, asks for permissions, and breaks on its own schedule. Here is the working set, by what it does, not by download count:

- **Prettier** (`esbenp.prettier-vscode`) — format on save so you stop arguing about it. The one setting that matters is making it the default formatter; otherwise it sits there doing nothing.
- **ESLint** (`dbaeumer.vscode-eslint`) — surfaces lint errors inline. Pointless without an ESLint config in the repo; it just goes quiet.
- **GitLens** (`eamodio.gitlens`) — inline blame: who wrote this line and when, without leaving the file. Turn off most of its other surface area or it gets loud.
- **Error Lens** (`usernamehw.errorlens`) — paints the error next to the code instead of making you hover. The single highest signal-to-noise extension on this list.
- **A language pack for whatever you actually write** — `ms-python.python` + `ms-python.vscode-pylance` for Python, `bradlc.vscode-tailwindcss` if you live in Tailwind, `redhat.vscode-yaml` if you edit CI configs. Don't install the others "just in case."

That's it. An icon theme (`PKief.material-icon-theme`) and a color theme are fine, but they're decoration, not tooling — install them if you like them, skip them without guilt.

Notice what's *not* here: Live Server (the dev server you already run from a terminal does this), Auto Rename Tag (modern Emmet handles most of it), and the pile of role-specific extensions that mega-lists pad the count with. The honest test for keeping an extension: if you can't name a thing it did for you this week, uninstall it.

## The actual hack: install from a file, not from the marketplace

The reason the marketplace UI is a trap is that clicking install 23 times is not reproducible. The `code` CLI is. List what you have:

```bash
$ code --list-extensions --show-versions
bradlc.vscode-tailwindcss@0.14.29
eliostruyf.vscode-front-matter@10.10.1
ms-python.debugpy@2026.6.0
ms-python.python@2026.4.0
ms-python.vscode-pylance@2026.2.1
ms-toolsai.jupyter@2025.9.1
...
```

That's real output from this machine, trimmed. Now turn it into something you can commit and replay. Save the IDs to a file:

```bash
# lh:run
cd "$(mktemp -d)"
# pretend these are the IDs `code --list-extensions` gave you
printf 'esbenp.prettier-vscode\ndbaeumer.vscode-eslint\neamodio.gitlens\nusernamehw.errorlens\n' > extensions.txt
cat extensions.txt
```

You'll know it worked when `extensions.txt` holds one extension ID per line. On a new machine, replay it:

```bash
cat extensions.txt | xargs -L1 code --install-extension
```

`xargs -L1` runs `code --install-extension` once per line. To show what the loop prints when an extension is already present, here's the same `code --install-extension` run against two IDs I actually had installed (not the four in the sample file above) — note it's idempotent, it doesn't reinstall, it just tells you:

```console
Installing extensions...
Extension 'ms-python.python' v2026.4.0 is already installed. Use '--force' option to update to latest version or provide '@<version>' to install a specific version, for example: 'ms-python.python@1.2.3'.
Installing extensions...
Extension 'bradlc.vscode-tailwindcss' v0.14.29 is already installed. Use '--force' option to update to latest version or provide '@<version>' to install a specific version, for example: 'bradlc.vscode-tailwindcss@1.2.3'.
```

Commit `extensions.txt` next to your dotfiles and your editor setup becomes a one-line restore. That, not the 23-item list, is the thing worth taking from this post.

## The part where it broke

Copy an extension ID wrong — drop the publisher prefix, or trust a typo in a blog post — and you get this. I triggered it on purpose with a fake ID:

```console
$ code --install-extension this.does-not-exist-zzz
Installing extensions...
Extension 'this.does-not-exist-zzz' not found.
Make sure you use the full extension ID, including the publisher, e.g.: ms-dotnettools.csharp
Failed Installing Extensions: this.does-not-exist-zzz
```

The message is actually helpful: **the full ID is `publisher.name`**, and "not found" almost always means a typo or a missing publisher, not a missing extension. The trap in the original curated list I rewrote this from had `zhuangtongfa.Material-theme` listed as "One Dark Pro" — that ID is real but the *name* is wrong, and that mislabeling is exactly how you end up installing the thing you didn't mean to. Always copy the ID from the marketplace page or from your own `code --list-extensions`, never retype it.

One more real-world gotcha: the `code` command has to be on your `PATH`. On macOS it isn't, by default. Open VS Code, run the command palette (Cmd+Shift+P), and pick **Shell Command: Install 'code' command in PATH**. You'll know it worked when `code --version` prints three lines (version, commit hash, arch) instead of `command not found`.

## The settings worth copying

Extensions do nothing without two or three settings turned on. These go in `settings.json` (command palette → "Preferences: Open User Settings (JSON)"):

```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "git.autofetch": true
}
```

`formatOnSave` is the one that pays for the whole list — it's what makes Prettier and ESLint actually run instead of just sitting in the sidebar. The rest are housekeeping: no trailing whitespace, a final newline, and Git quietly fetching so your branch status isn't a lie.

## What it costs and the free alternative

The extensions on this list are free. The real cost is startup time and attention: every extension you add is one more thing that loads, updates, and occasionally breaks an editor reload. The "free alternative" to most curated lists is *fewer extensions* — VS Code's built-in Emmet, search, and Git support already cover a surprising amount of what people install plugins for.

If you want the install-from-a-file workflow without writing the file by hand, the **Settings Sync** feature built into VS Code (sign in with GitHub/Microsoft) syncs your extensions and settings across machines automatically. It's the zero-config version; the `extensions.txt` approach is the version-controlled, no-account version. Pick based on whether you'd rather trust a sync service or a file in your dotfiles repo.

## Level up

The folks at our sister site [IT-Journey](https://it-journey.dev) turn this into a guided run, if you want structure instead of a list:

- [VS Code Mastery Quest](https://it-journey.dev/quests/level-0000-vscode-mastery-quest/)
- [Git Basics Quest](https://it-journey.dev/quests/0000/git-basics/)

## When it goes wrong

- **`code: command not found`** — the shell command isn't on PATH. Run "Shell Command: Install 'code' command in PATH" from the command palette.
- **`Extension '...' not found`** — typo in the ID, or you dropped the `publisher.` prefix. Copy it from `code --list-extensions` or the marketplace page, don't retype.
- **"already installed"** — that's not an error; the install is idempotent. Add `--force` only if you actually want to update.
- **Prettier/ESLint do nothing** — they need a config (`.prettierrc`, `eslint.config.js`) in the repo and `formatOnSave` turned on. With neither, they're inert.
