---
title: "Tangle a markdown file into runnable scripts, one file per fenced language"
description: "Turn a README's fenced code blocks into real .sh and .py files — one file per language, prose dropped, plus the closed-file crash that ate version one."
date: 2024-06-02
categories: [Hacks]
tags: [shell, ci-cd, web-dev]
author: amr
excerpt: "Your setup doc already contains every command. Stop copy-pasting them one block at a time — extract them into runnable files in one pass."
preview: /images/previews/section-hacks.svg
permalink: /hacks/markdown-code-to-scripts/
---
You wrote a beautiful README. It has the install commands, the build commands, the "now run this" commands — all neatly fenced in code blocks, surrounded by paragraphs explaining what each one does. Then someone clones the repo and does what everyone does: copy block one, paste, run, scroll, copy block two, paste, run. Forty times. Missing one.

The commands are already written down. They are sitting in the file. The only thing standing between the document and a runnable script is the prose in between and the fences around the code.

This is the part where you stop pasting. We are going to "tangle" the file — pull each fenced language out into its own runnable file, drop the prose, and keep the code in order. A bash block becomes a `.sh`. A python block becomes a `.py`. Two ideas, one pass.

## What "tangle" means here

The rule is small enough to say in one breath: read the markdown line by line; when a line starts with a fence and a language name, start writing to a file for that language; when the next fence closes the block, stop; everything outside a fence gets thrown away. Same-language blocks append to the same file, so a doc with three bash blocks produces one `.sh` with all three in order.

That last detail — *one file per language, appended* — is the whole point. It is also where the naive version falls over, which we will get to.

## The one-liner: `awk` and nothing else

No dependency you do not already have. `awk` reads the file line by line, which is exactly the shape of this problem.

```bash
# lh:run
cd "$(mktemp -d)"
F='```'   # one fence, kept in a variable so this snippet has no bare fence line

# Build a sample notes file with two fenced languages plus an inline-code edge case.
{
  printf '%s\n'   '# Setup notes'
  printf '%s\n'   ''
  printf '%s\n'   'Install deps, then run the helper. Inline `code` must not trip the parser.'
  printf '%s\n'   ''
  printf '%s\n'   "${F}bash"
  printf '%s\n'   'set -euo pipefail'
  printf '%s\n'   'echo "deps installed"'
  printf '%s\n'   "${F}"
  printf '%s\n'   ''
  printf '%s\n'   'Then the python part.'
  printf '%s\n'   ''
  printf '%s\n'   "${F}python"
  printf '%s\n'   'print("hello from python")'
  printf '%s\n'   "${F}"
  printf '%s\n'   ''
  printf '%s\n'   'A second bash block appends to the same file.'
  printf '%s\n'   ''
  printf '%s\n'   "${F}bash"
  printf '%s\n'   'echo "second block"'
  printf '%s\n'   "${F}"
} > notes.md

# Tangle: one file per fenced language; prose dropped; act on a fence only when
# it is the start of a line (so inline `code` is ignored).
awk -v stem=notes -v F='```' '
  index($0, F) == 1 {
    if (cur) { cur=""; next }                          # a fence while open = close
    lang = substr($0, 4); gsub(/[ \t]+$/, "", lang)    # text after the fence
    ext = ""
    if (lang=="bash" || lang=="shell" || lang=="sh") ext="sh"
    else if (lang=="python" || lang=="python3")      ext="py"
    if (ext != "") {
      cur = stem "." ext
      if (!(cur in seen)) {                            # first block for this language
        seen[cur] = 1
        print (ext=="sh" ? "#!/usr/bin/env bash" : "#!/usr/bin/env python3") > cur
      }
    }
    next
  }
  cur { print >> cur }                                 # inside a block: copy the line
' notes.md

echo "== files produced =="
ls notes.sh notes.py
echo
echo "== notes.sh =="
cat notes.sh
echo
echo "== run notes.sh =="
bash notes.sh
```

We ran that block (on BSD `awk`, the stricter of the two common variants). Here is the real output:

```
== files produced ==
notes.py
notes.sh

== notes.sh ==
#!/usr/bin/env bash
set -euo pipefail
echo "deps installed"
echo "second block"

== run notes.sh ==
deps installed
second block
```

You'll know it worked when `notes.sh` contains **both** bash blocks — `deps installed` *and* `second block` — under a single shebang, and running it prints both lines. The python block landed in `notes.py` untouched, and the prose ("Setup notes", "Then the python part") is nowhere in either file. That is the tell: prose dropped, code kept, order preserved.

Read the `awk` back:

- `index($0, F) == 1` is true only when the line **starts** with the fence. That is what makes inline `` `code` `` in a sentence safe — a backtick mid-line is index 5, not 1, so it is ignored.
- `cur` holds the current output filename. When it is set, we are inside a block and the last line copies through verbatim: `cur { print >> cur }`.
- `seen[cur]` writes the shebang exactly once per file, so the second bash block appends instead of clobbering.
- `> cur` truncates on first open; `>> cur` appends after. Getting those two backwards is how you end up with only the last block of each language.

## The part where it broke

The first version of this was in Python, and it crashed in the most on-brand way possible: it tried to write to a file it had already closed.

The shape of the bug was a per-block file handle. On the opening fence it did `open(...)`; on the closing fence it did `language_file.close()` and set the mode back to "not in a block." So far fine. But the markdown line *after* a closing fence — a blank line, a paragraph — still hit the "we have a file handle, write this as a comment" branch:

```python
if language_mode:
    language_file.write(line)
else:
    if language_file:
        language_file.write(f'# {line}')   # <-- the file is already closed
```

The handle was non-`None` (we never reset it), but it was closed. Python is blunt about it:

```
ValueError: I/O operation on closed file.
```

We reproduced that exact traceback before fixing it — the crash is real, not a story.

There were actually two bugs hiding in one. Fixing the close-then-write crash by "only write when inside a block" exposed the second: a fresh file handle per *block* meant the second bash block reopened `notes.sh` in write mode and clobbered the first. The total looked plausible — one bash block of content — right up until you noticed a block had silently vanished.

The fix for both is the same idea the `awk` version is built around: **key the open files by language, not by block.** Open each language's file once, keep it in a dictionary, append every block to it, and only ever switch modes — never close and reopen mid-document. Here is the Python that survives, if you would rather have a script you can extend:

```python
#!/usr/bin/env python3
import sys

EXT = {"bash": "sh", "shell": "sh", "sh": "sh", "python": "py", "python3": "py"}
SHEBANG = {"sh": "#!/usr/bin/env bash", "py": "#!/usr/bin/env python3"}

def tangle(md_path):
    stem = md_path[:-3] if md_path.endswith(".md") else md_path
    files, current = {}, None
    with open(md_path) as md:
        for line in md:
            if line.startswith("```"):          # start-of-line fences only
                if current:
                    current = None              # closing fence: leave the block
                else:
                    ext = EXT.get(line[3:].strip())
                    if ext:
                        path = f"{stem}.{ext}"
                        if path not in files:   # open once, per language
                            f = open(path, "w")
                            f.write(SHEBANG[ext] + "\n")
                            files[path] = f
                        current = files[path]
                continue
            if current:
                current.write(line)
    for f in files.values():
        f.close()
    return list(files)

if __name__ == "__main__":
    for p in tangle(sys.argv[1]):
        print(p)
```

We ran this against the same `notes.md` and it produced byte-identical `notes.sh` and `notes.py` to the `awk` version, and both executed clean. The difference from the broken original is entirely structural: files live in `files = {}` and are closed once at the end, never inside the loop.

## When this goes wrong elsewhere

- **Indented or nested fences.** The start-of-line check (`index($0, F) == 1` / `line.startswith`) means a fence indented under a list item will not be seen as a fence. That is usually what you want for documentation, but if your blocks live inside bullet points, this skips them. Un-indent them or pre-process first.
- **Tildes instead of backticks.** Some markdown uses `~~~` fences. Neither version handles those — add a second pattern if your docs do.
- **The block isn't actually runnable.** Tangling is mechanical; it does not check that the commands work. A doc full of `apt-get install ...` examples becomes a `.sh` that needs root and a package manager. The tangler hands you a script; it does not promise the script is safe to run unread. Read it first, the same as anything you paste from the internet.
- **Language names you didn't map.** A ` ```yaml ` or ` ```json ` block is silently dropped because it is not in the extension table. That is intentional — you rarely want to "run" a config block — but if you do want it extracted, add it to the map with whatever extension makes sense (and no shebang).

## The honest accounting

This does not turn a README into a tested install script. It turns it into a *runnable* one, which is a smaller and more honest claim: the commands you already documented, in one file, in order, with the prose stripped out. Whether they work is still on whoever wrote the doc.

The real win is that the document and the script can stop drifting apart. Edit the README, re-tangle, and the script is current — instead of the README saying one thing and the `setup.sh` next to it quietly saying another.
