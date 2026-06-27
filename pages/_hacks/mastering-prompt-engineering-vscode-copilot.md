---
title: "Prompt patterns that survive a code review: RCTF, few-shot, and a reusable Copilot template library"
description: "Keep Copilot prompts as files: structure them with RCTF, verify with grep, and fix the wrong-path bug that makes Copilot ignore your project rules."
date: 2025-11-26
collection: hacks
author: amr
excerpt: "Treat prompts like code: a file, a structure, a check. Plus the one-character path mistake that makes Copilot silently ignore every rule you wrote."
tags: [copilot, prompt-engineering, vscode, github, productivity]
---

Every "prompt engineering" guide promises a magic incantation that turns Copilot into a tireless senior engineer. Then it tells you to "be specific" and "give it context" and sends you on your way, as if you weren't going to type the same wall of instructions into the chat box for the eleventh time today and get a slightly different answer on each.

The useful version is more boring. You stop chatting and start writing files. A prompt you keep in the repo is a prompt you can structure, diff, grade, and reuse — and one Copilot can read on its own without you pasting anything.

Here are the patterns worth keeping from the long version of this advice, as files you can drop into `.github/` today — and the one-character path mistake that makes Copilot ignore the whole thing without telling you.

## The structure that makes a prompt repeatable: RCTF

"Be specific" is unfalsifiable, so the model wanders. A structure is something the model can hit and you can check against. The one that earns its keep is **RCTF — Role, Context, Task, Format**:

```markdown
[ROLE] You are a senior Python reviewer.

[CONTEXT] A user-registration API needs robust email validation.

[TASK] Write a function that validates email format, handles the empty
string, a missing @, and a bad domain, and returns (is_valid: bool,
error: str | None).

[CONSTRAINTS] Python 3.10+, stdlib only, <=25 lines, docstring with examples.

[FORMAT] The function, then 3 test cases showing usage.
```

The four tags aren't decoration — each one fixes a specific failure. No `[ROLE]` and the model picks a generic persona. No `[CONTEXT]` and it solves a different problem than yours. No `[CONSTRAINTS]` and it reaches for a library you didn't want. No `[FORMAT]` and you get prose where you wanted code.

**You'll know a prompt is complete when** a `grep` for all four tags comes back clean. Save the prompt to a file and check it before you trust it:

```bash
# lh:run
cd "$(mktemp -d)"
cat > review.prompt.md <<'EOF'
[ROLE] You are a senior Python reviewer.
[CONTEXT] A user-registration API needs robust email validation.
[TASK] Write a function that validates email format, handles empty/missing-@/bad-domain, returns (bool, str|None).
[CONSTRAINTS] Python 3.10+, stdlib only, <=25 lines, docstring with examples.
[FORMAT] The function, then 3 test cases.
EOF
for tag in ROLE CONTEXT TASK FORMAT; do
  if grep -q "\[$tag\]" review.prompt.md; then echo "$tag: present"; else echo "$tag: MISSING"; fi
done
```

```console
ROLE: present
CONTEXT: present
TASK: present
FORMAT: present
```

That's real output from running the block above. If a tag prints `MISSING`, the prompt is incomplete — add the section before you wonder why the model ignored a constraint you never actually wrote down.

## Two patterns to reach for when RCTF isn't enough

RCTF covers most requests. Two others are worth knowing by name, because they fix problems RCTF doesn't.

**Few-shot** — you show examples instead of describing the format. Use it when the output shape is custom enough that describing it is harder than demonstrating it:

```markdown
Convert function names to one-line comments:

getUserById        -> // Retrieves a user by their unique identifier
validateEmail      -> // Validates a string as an email address
calculateTotal     -> // Computes the total including tax and discounts

Now convert:
processPaymentQueue ->
```

Three examples set the pattern; the model fills the fourth in the same shape. Few-shot is the lever for "I want it formatted exactly like *this*" — when a paragraph of instructions keeps producing something almost-but-not-quite right.

**Chain-of-thought** — you force the steps before the answer. Use it for multi-step reasoning where the model otherwise leaps to a confident wrong conclusion:

```markdown
Design a caching strategy for a real-time dashboard.

Work through it step by step, explaining each before the next:
1. Which data changes often vs. rarely?
2. What are the read/write patterns?
3. Which cache-invalidation strategy fits?
4. The architecture, with trade-offs.
```

The numbered steps stop the model from skipping straight to "use Redis" without saying why. You're trading a longer response for one you can actually audit.

## Put the project rules where Copilot reads them automatically

RCTF fixes one prompt. Project instructions fix every prompt, because Copilot reads them on its own — no pasting. Create `.github/copilot-instructions.md`:

```markdown
# Project Copilot Instructions

## Code style
- TypeScript, strict mode on.
- Every exported function has a JSDoc comment.
- Max function length: 30 lines.

## Layout
- src/services/   business logic
- src/components/ React components
- src/utils/      pure helpers

## Testing
- Jest + React Testing Library, name tests *.test.ts

## Security
- Never hardcode credentials. Validate all input. Parameterized queries only.
```

Now every suggestion arrives already knowing your conventions instead of inventing its own. This is the file that pays off most: write the rules once, stop repeating them in every prompt.

**You'll know it landed when** the file exists at exactly that path — which is also where this quietly goes wrong, so read the next section before you celebrate.

## The part where it broke: the path is one character off and Copilot says nothing

This is the failure that costs an afternoon, because there's no error. Copilot acts as if your instructions don't exist — and they don't, to it.

Copilot reads exactly one path: `.github/copilot-instructions.md`. Not `.github/copilot/instructions.md`. Not `.github/instructions.md`. The intuitive guess — a `copilot/` folder with an `instructions.md` inside — is wrong, and nothing warns you. Your rules sit in the repo, version-controlled and ignored.

Here's the wrong layout and the check that catches it:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p .github/copilot
cat > .github/copilot/instructions.md <<'EOF'
# Project Copilot Instructions
- TypeScript, strict mode on.
EOF

echo "=== you THINK Copilot reads this ==="
find .github -type f | sort
echo
echo "=== Copilot only reads .github/copilot-instructions.md ==="
if [ -f .github/copilot-instructions.md ]; then
  echo "OK: file is at the path Copilot reads"
else
  echo "MISSING: .github/copilot-instructions.md not found"
  echo "you have these instead:"
  find .github -name '*instructions*' -type f
fi
```

```console
=== you THINK Copilot reads this ===
.github/copilot/instructions.md

=== Copilot only reads .github/copilot-instructions.md ===
MISSING: .github/copilot-instructions.md not found
you have these instead:
.github/copilot/instructions.md
```

That's real output. The file is right there, perfectly written, in the folder Copilot never opens. The fix is a one-line move — `git mv .github/copilot/instructions.md .github/copilot-instructions.md` — but you only know to do it once you've checked the exact path. Reload the VS Code window afterward (`Cmd/Ctrl + Shift + P` -> "Reload Window") so the change is picked up.

## The reusable prompt library, as files with a self-check

The prompts you write twice deserve to live in `.github/prompts/` with a tiny verifier, so a half-finished template doesn't slip into the set. Build the directory and check that each prompt has the keys it needs:

{% raw %}
```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p .github/prompts
cat > .github/copilot-instructions.md <<'EOF'
# Project Copilot Instructions
- TypeScript, strict mode on.
- Every exported function has a JSDoc comment.
EOF
cat > .github/prompts/code-review.prompt.md <<'EOF'
---
name: code-review
description: Structured code review prompt
inputs:
  - focus_area
---
[ROLE] You are a senior reviewer focused on {{ inputs.focus_area }}.
[TASK] Review the provided code. For each issue report severity, location, the problem, and a fix.
EOF

echo "=== files on disk ==="
find .github -type f | sort
echo
echo "=== does Copilot's instruction file exist at the right path? ==="
test -f .github/copilot-instructions.md && echo "FOUND: .github/copilot-instructions.md"
echo
echo "=== does the prompt template carry its required keys? ==="
awk '/^name:/{n=1} /^description:/{d=1} END{print "name:", (n?"yes":"NO"); print "description:", (d?"yes":"NO")}' \
  .github/prompts/code-review.prompt.md
```
{% endraw %}

```console
=== files on disk ===
.github/copilot-instructions.md
.github/prompts/code-review.prompt.md
=== does Copilot's instruction file exist at the right path? ===
FOUND: .github/copilot-instructions.md
=== does the prompt template carry its required keys? ===
name: yes
description: yes
```

That's real output. The `awk` line is your gate: a template missing `name:` or `description:` prints `NO`, and you fix it before it joins the library. Grow the directory one tested prompt at a time — `generate-tests.prompt.md`, `refactor.prompt.md`, `debug.prompt.md` — and keep a `README.md` cataloging what each one does, so the next person (or the next you) doesn't reinvent the code-review prompt from scratch.

## When this goes wrong

The honest failure modes, in the order you'll meet them:

- **Copilot ignores your project rules** — almost always the wrong path. Run the `find .github -name '*instructions*'` check above. The file must be `.github/copilot-instructions.md`, plain Markdown, no YAML frontmatter, and you must reload the window after creating it.
- **Same prompt, different quality each run** — you're under-specifying. Add `[CONSTRAINTS]`, give a few-shot example, and pin the `[FORMAT]`. The grep check tells you which RCTF section you skipped.
- **Output too long or too short** — say so in the prompt. "Be concise, max 25 lines" or "include a worked example." The model defaults to whatever it defaulted to last time, which is to say, unpredictably.
- **The template library rots** — prompts get edited in the chat box and the file drifts out of date. The fix is the same discipline as the rest: edit the file, not the chat. The file is the source of truth precisely because you can diff it.

## The honest accounting

None of this makes Copilot smarter. It makes it repeatable. You trade a vague request you re-explain every session for a structured one you can version, diff, and grade — and a project-instructions file means you stop re-explaining your conventions on every single prompt.

The real win is the afternoon you don't lose to the wrong path. A perfectly written `.github/copilot/instructions.md` that Copilot never reads is worse than nothing, because it *looks* done. Check the exact path, run the grep, and the rules you wrote are the rules the model actually follows.

The judgment is still yours. A structured prompt produces a confident, well-formatted answer whether or not it's correct — RCTF improves the *shape* of the output, not its truth. Read the generated code like you'd read a stranger's pull request, every time.

## Level up

This hack is the practical, copy-the-files version. For the longer, structured walkthrough — patterns, exercises, and the PDCA loop for iterating on prompts — our serious sister site has the quest:

- [AI-Assisted Development](https://it-journey.dev/quests/ai-assisted-development/)
