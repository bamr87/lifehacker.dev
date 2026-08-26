---
title: "Fix the tofu boxes in your terminal prompt: install a Nerd Font, then prove it actually stuck"
description: "Your starship/powerline prompt renders as boxes because the glyphs need a Nerd Font. Install one, point the TERMINAL at it, and verify coverage the honest way."
date: 2026-08-14
categories: [Hacks]
tags: [shell]
author: edge
preview: /images/previews/fix-the-tofu-boxes-in-your-terminal-prompt-install.jpg
excerpt: "The install is three commands. The bug is that fc-match will look you in the eye and lie about it."
permalink: /hacks/nerd-font-tofu-boxes/
---
Someone handed me a prompt that was supposed to show a git branch, a folder, and a smug little powerline arrow. It showed three boxes: `□ □ □`. In the trade we call that **tofu** — the placeholder a font renders when it has no glyph for the codepoint you asked for. The fix is famous and short: install a Nerd Font. So I installed one, and then I did the thing I always do, which is refuse to believe it worked until a command told me it worked.

That refusal is the whole post. The install is three lines. The part that eats an afternoon is that the standard "did it work?" command is a liar, and I have the receipts.

If you want the earnest, no-grudge version of this quest, IT-Journey wrote it up as [Nerd Font Enchantment](https://it-journey.dev/quests/0010/nerd-font-enchantment/). I'm here to feed the same font a codepoint it doesn't have and watch what breaks.

## What the tofu actually is

Your prompt tool (starship, powerline, oh-my-zsh, p10k) prints Unicode characters up in the Private Use Area — things like `U+E0B0` (the powerline arrow) and `U+E0A0` (the git branch). Regular fonts don't map those slots. A Nerd Font is an otherwise normal monospace face with a fat block of icon glyphs patched in — **12,759 codepoints** of coverage all told — so those slots finally point at a glyph instead of at nothing.

I counted that whole-charset number instead of trusting the marketing:

```bash
fc-query --format='%{charset}\n' ~/.local/share/fonts/MesloLGSNerdFont-Regular.ttf \
  | ruby -e 'n=0; STDIN.read.split.each{|r| a,b=r.split("-"); lo=a.to_i(16); hi=(b||a).to_i(16); n+=hi-lo+1 if hi>=lo}; puts "#{n} codepoints"'
# => 12759 codepoints
```

Real number, real font, ran it on Ubuntu 24.04. Twelve thousand of those you will never type. Six of them are the reason your prompt looks broken.

## The install (Linux, actually run)

Before I touched anything, the box was empty on purpose — no Nerd Font present:

```bash
fc-list | grep -i meslo
# (nothing)
```

Then, the whole fix:

```bash
mkdir -p ~/.local/share/fonts
curl -fL -o /tmp/Meslo.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip
unzip -o -q /tmp/Meslo.zip -d /tmp/meslo
cp /tmp/meslo/MesloLGSNerdFont-Regular.ttf ~/.local/share/fonts/
fc-cache -f ~/.local/share/fonts
```

You'll know it worked when fontconfig admits the font exists:

```bash
fc-list | grep -i meslo
# /home/runner/.local/share/fonts/MesloLGSNerdFont-Regular.ttf: MesloLGS Nerd Font:style=Regular
```

That output is captured, not imagined. Note the `-f` on `fc-cache`, not the `-fv` every tutorial copies from every other tutorial — `-v` just floods you with a directory-by-directory travelogue you will not read.

On macOS the same fix is one line, and I'm telling you rather than showing you because I ran this on Linux and I don't publish output I didn't produce:

```bash
# macOS — I did not run this box; it's the documented path, not captured output
brew install --cask font-meslo-lg-nerd-font
```

## The bug: `fc-match` is a liar

Here's where the afternoon went. The internet's favorite verification is `fc-match ":charset=e0b0"` — "which font would cover this codepoint?" I ran it against a codepoint I *know* nothing on the box has, `U+105000`, way out past the assigned planes:

```bash
fc-match ":charset=105000"
# DejaVuSans.ttf: "DejaVu Sans" "Book"
```

DejaVu Sans does not contain `U+105000`. Nothing does. `fc-match` **still named a font**, with total confidence, because its job is "give me your single best guess and never return empty-handed." Feed it a glyph nobody has and it hands you a fallback face and a straight face. If you verify a Nerd Font install this way, `fc-match` will congratulate you on icons you do not have.

**The nitpick, and the failure it prevents:** trusting `fc-match` for coverage tells you the install succeeded when it didn't, so you burn an hour re-editing your prompt config to fix a font problem `fc-match` swore wasn't there.

The honest command is `fc-list ":charset=..."`, which lists **only** fonts that genuinely carry the codepoint — zero of them if it's tofu:

```bash
$ fc-list ":charset=105000" family
$          # empty. This is what "you will see a box" looks like from the shell.

$ fc-list ":charset=e0b0" family
MesloLGS Nerd Font    # covered for real
```

I wrapped that into a test card and ran it against a spread of prompt glyphs. This output is captured:

```console
$ nerdcheck e0b0 e0a0 f09b f015 e5fa f8ff 105000
U+e0b0   COVERED   by: MesloLGS Nerd Font
U+e0a0   COVERED   by: MesloLGS Nerd Font
U+f09b   COVERED   by: MesloLGS Nerd Font
U+f015   COVERED   by: MesloLGS Nerd Font
U+e5fa   COVERED   by: MesloLGS Nerd Font
U+f8ff   COVERED   by: Lato
U+105000 TOFU      (no installed font has this glyph)
```

Two findings from one table:

- `U+105000` is honest tofu — nothing covers it, you'd get a box.
- `U+F8FF` reports **COVERED by Lato**. That's the Apple-logo PUA slot, and Lato just... put a glyph there. "Covered" means *some* font has *a* glyph at that codepoint — not that it's the icon you wanted. The third weird case in a table is always the one that teaches you something.

Here's `nerdcheck`, which is just `fc-list` with a bib on:

```bash
#!/usr/bin/env bash
# nerdcheck: does an installed font actually cover the icon, or is it tofu?
for cp in "$@"; do
  if [ -n "$(fc-list ":charset=$cp" family)" ]; then
    printf 'U+%-6s COVERED   by: %s\n' "$cp" "$(fc-list ":charset=$cp" family | sort -u | head -1)"
  else
    printf 'U+%-6s TOFU      (no installed font has this glyph)\n' "$cp"
  fi
done
```

## The step everyone misses: point the *terminal* at it

The font can be installed, verified, coverage confirmed — and your prompt still shows boxes. Because you set the font on the wrong thing.

In VS Code, `editor.fontFamily` styles the code editor. It does **not** touch the integrated terminal, which reads its own setting. The prompt lives in the terminal. So you also need:

```jsonc
// settings.json — config to paste, not captured output
{
  "editor.fontFamily": "MesloLGS Nerd Font, monospace",
  "terminal.integrated.fontFamily": "MesloLGS Nerd Font"
}
```

In a standalone terminal (GNOME Terminal, iTerm2, Windows Terminal, Alacritty), the equivalent is the **profile's** font field, not a global preference. Set it on the profile you actually launch. The failure this prevents: you "fixed the font," reopened the editor, saw boxes in the terminal pane, and concluded the install failed — when the install was fine and the terminal simply never got the memo.

## The variant trap, and where fontconfig taps out

Nerd Fonts ship three flavors of each face. I installed all three of MesloLGS and asked fontconfig what it thought of them:

| Variant | fontconfig `spacing` | What it means |
|---|---|---|
| `MesloLGS Nerd Font` | `100` | reports monospace |
| `MesloLGS Nerd Font Mono` | `100` | reports monospace |
| `MesloLGS Nerd Font Propo` | *(none)* | proportional / dual-width |

Real output — `spacing=100` is fontconfig's flag for monospace, absent means proportional.

The common advice is "always pick the **Mono** variant in a terminal or the double-width icons overlap." Mostly right, but notice what the table exposes: for MesloLGS, the plain `Nerd Font` face **also** reports `100`. fontconfig's `spacing` is a single coarse flag; it can't tell you whether a *specific* icon glyph renders one cell wide or two. So you cannot pick the terminal-safe variant by querying metadata — the metadata says both are monospace. You confirm icon width by looking at a rendered prompt in your actual terminal, or you pick `Mono` and stop worrying. The nitpick: don't automate the variant choice off `spacing`; it doesn't carry the information you need, and a script that trusts it will happily hand a terminal the wrong face.

## When this goes wrong

- **Glyphs render but they're blurry.** Not a font problem — GPU acceleration. In VS Code's terminal, `"terminal.integrated.gpuAcceleration": "off"`. (Config, not captured; I have no GPU on this box to reproduce the blur, so I won't pretend I did.)
- **`fc-list | grep meslo` is empty after install.** The cache didn't see the directory. Re-run `fc-cache -f ~/.local/share/fonts` and confirm the `.ttf` actually landed in `~/.local/share/fonts/` and isn't still sitting in `/tmp`.
- **You verified with `fc-match` and it "passed."** Re-read the middle of this post. Use `fc-list ":charset="`.
- **Icons show but overlap the next character.** Switch to the `Mono` variant on the terminal profile.

## Verdict, on the survives-a-Tuesday scale

Installing the font: **survives a normal Tuesday.** Three commands, deterministic, `fc-cache` doesn't flinch.

Verifying the install: **survives a bad Tuesday only if you throw out `fc-match`.** The tool most guides hand you returns a confident wrong answer for any codepoint you don't have, which is exactly the case you're trying to detect. `fc-list ":charset="` is the one that survives the Tuesday where the intern has sudo and swears the icons are installed.

The font did not break under a garbage codepoint, a false-positive PUA slot, or three near-identical variants. It sat there being correct. Grudging respect: the failure here was never the font. It was every command that told you the font was fine without checking.
