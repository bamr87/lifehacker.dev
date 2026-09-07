---
title: "Count the tokens before you paste the whole file into the prompt"
description: "A token isn't a word — it's ~3-4 characters, billed and leaked one at a time. The two-line tiktoken counter I ran, and why chars/4 is a budget, not a limit."
date: 2026-09-07
preview: /images/previews/count-the-tokens-before-you-paste-the-whole-file-i.svg
categories: [Hacks]
tags: [data, security]
author: cass
excerpt: "Every token you paste is a byte that left the building — priced, logged, and gone. Count them first."
permalink: /hacks/count-tokens-before-you-paste/
---
Nobody threat-models the paste buffer. It sits there in your clipboard, the most trusted process on the machine, and then someone types "just paste the whole file in and ask the model to fix it" and 9,000 characters of your private repository leave the building at the speed of Ctrl-V. The bill is measured in tokens. So is the context window. And — this is the part the pricing page won't put in bold — so is the blast radius, because every token you send is a byte you no longer control. It's on someone else's server now, in someone else's logs, and depending on which checkbox you didn't read, someone else's next training run.

The convenience feature here is "context is basically free, paste liberally." Convenience is an attack surface with better marketing. Let's count what we're actually shipping out the door.

## A token is not a word, and the invoice knows it

The unit is a token, and a token is roughly 3–4 characters — a chunk of a word, not a word. "Just paste the file" is an invoice you didn't read and a data export you didn't authorize, both denominated in a unit you didn't measure. So measure it. I did.

```python
# pip install tiktoken
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")   # the GPT-4 / 3.5 vocabulary
def count(text): return len(enc.encode(text))
```

That's the whole tool. Here is what it said about three real strings I fed it:

```
   2 tokens |   12 chars | one word 'tokenization'
  10 tokens |   44 chars | a prose sentence
  10 tokens |   45 chars | a line of code
```

`tokenization` is one English word and two tokens. The ratio wanders from 4-ish for plain prose to worse for anything dense. **You'll know it's working when** `count("tokenization")` returns `2` and not `1` — if it returns the word count, you're measuring the wrong thing, which is the entire problem in one line.

Now point it at something the size of a real "just paste it" — a 185-line shell script from this very repo:

```
scripts/ci/build.sh: 9614 chars, 185 lines, 2623 tokens (cl100k)
```

Twenty-six hundred tokens for one utility file. That's the thing you were about to paste "for context," priced and logged and, if the terms say so, memorized. Assume breach: treat that number as the size of the leak, not the size of the prompt.

## The tokenizer is model-specific, which is where "chars ÷ 4" betrays you

Here is the same 80-character line of Python run through three different tokenizers:

```
  21 tokens | cl100k_base   (GPT-4)
  21 tokens | o200k_base    (GPT-4o)
  32 tokens | p50k_base     (older Codex-era)
  -- chars/4 estimate: 20
```

Same string. A 52% swing depending on whose vocabulary you ask. A GPT tokenizer and a Llama tokenizer will disagree on your string too — there is no universal token. "Characters divided by four" landed at 20 here, which was a fine *budget* and a wrong *hard limit*: it under-counted the model that mattered by more than half.

Code and whitespace are the worst offenders. Indentation isn't free — every level of nesting is real tokens:

```
  6 tokens | 'if x: return 1'                        (flat)
  9 tokens | '        if x:\n            return 1\n'  (indented)
```

Same two statements, 50% more tokens once you nest them the way real code is nested. Minified-ish, symbol-heavy code ran *over* the chars/4 estimate; padded prose ran under it. So chars/4 is a napkin, not a gate.

When the cap actually matters — you're near the context limit, or the per-request bill is load-bearing — don't guess the encoding. Ask for it by model name and let the library map it:

```python
import tiktoken
for model in ["gpt-4o", "gpt-4", "gpt-3.5-turbo"]:
    print(model, "->", tiktoken.encoding_for_model(model).name)
# gpt-4o         -> o200k_base
# gpt-4          -> cl100k_base
# gpt-3.5-turbo  -> cl100k_base
```

Every command above I actually ran; the numbers are copied out of the terminal, not estimated. If you already live in Hugging Face land, the tokenizer you're serving with counts the same way — no extra dependency:

```python
# lh:norun — illustrative; needs a model download, so verify against your own
from transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained("meta-llama/Llama-3.1-8B")
len(tok.encode(text))
```

## The three mitigations that actually matter

**SEVERITY: your clipboard. ATTACK VECTOR: the phrase "just paste the whole file."** Ranked, tested, none of them "be more careful":

**One — count before you send.** The two-line `tiktoken` counter above, wired into whatever pastes text into a model. Not to save four cents; to know the size of what left the building before it leaves. A number you measured is a number you can refuse. I ran it against a real repo file and got 2,623 tokens I would otherwise have shipped blind.

**Two — send the slice, not the file.** The failing function, the relevant diff, the twelve lines around the error — not the whole module, and never the whole repo. This cuts the bill and the blast radius with the same keystroke: fewer tokens out the door means fewer of your secrets, keys, and customer rows sitting in a third party's request log. Before you paste, grep the selection for anything shaped like `.env`, an API key, or a hostname, and cut it. The model does not need your `AWS_SECRET_ACCESS_KEY` to fix your for-loop.

**Three — pin the tokenizer to the model when the cap is real.** `encoding_for_model`, not chars/4, whenever hitting the limit means a truncated answer or a surprise bill. Use chars/4 for a shrug-level estimate; use the real tokenizer the moment the number has to be right. The 21-vs-32 gap above is the difference between "fits" and "silently truncated the end of your file, including the part with the bug."

## When this goes wrong

`tiktoken` counts tokens; it does not count your *conversation*. The real request includes the system prompt, the chat scaffolding, prior turns, and any tool-call schema — so your measured 2,623 is a floor, not the total. And it's a counter, not a redactor: it will happily and precisely count the tokens in the credentials you're about to leak. It tells you how big the mistake is. Not making the mistake is still your job.

The paste buffer remains the most trusted process on your machine, and it should not be. Count what's in it. Then send less than you think you need — the model will ask if it wants more, and unlike your clipboard, it's the one thing in this transaction that can't keep a copy you didn't mean to give it.

This lifehacker angle started from IT-Journey's walk through [tokenization and transformers](https://it-journey.dev/quests/1101/natural-language-processing/); they explain why the tokenizer exists, and I'm here to remind you it's also a turnstile counting everything you feed it.
