---
title: "A reusable GPT-4o system prompt for dark-to-hopeful satire (and how to adapt it)"
description: "A four-beat satire system prompt you can store in a file, plus the jq trick that stops a multi-line prompt from breaking your JSON request body."
date: 2024-06-27
categories: [Hacks]
tags: [web-dev, data]
author: amr
excerpt: "Stop pasting a wall of instructions into the chat box. Put the prompt in a file, build the request with jq, and fix the newline that breaks the body."
preview: /images/previews/section-hacks.svg
permalink: /hacks/gpt-prompt-engineering/
---
Every guide to "prompt engineering" promises you a magic incantation that turns a chatbot into a tireless content factory. Then it hands you a paragraph that says "be creative and engaging" and wishes you luck.

The useful version is more boring and more reliable: you write the structure down once, store it in a file, and feed it to the model the same way every time. The model stops freelancing because you stopped asking it to.

Here is a system prompt that reliably produces one specific thing — a short satirical piece that opens grim and lands on something a reader can actually do — and the part where wiring it into an API call breaks, with the real error.

## The prompt, as a file you keep

Don't paste a long prompt into the chat box and re-paste it every session. Save it. Editing one file beats hunting through scrollback for the version that worked.

```bash
cat > system-prompt.txt <<'EOF'
You write short satirical pieces. Structure every piece in exactly four
beats, in this order, and label nothing:

1. GRIM OPEN: state the situation at its bleakest, deadpan.
2. DARK MIDDLE: one sharp joke that sits with the bleakness.
3. THE PIVOT: introduce one true, verifiable fact that reframes it.
4. ACTIONABLE CLOSE: end with one concrete step the reader can take today.

Rules:
- The fact in beat 3 must be real and checkable. If you are unsure, omit it.
- The step in beat 4 must be something a reader could do this afternoon.
- Never explain the joke. Never use the word "hilarious".
EOF
```

The structure is the whole trick. "Be funny" is unfalsifiable, so the model wanders. "Four beats, in this order, the third one is a checkable fact" is a spec, and a spec is something the model can actually hit — and something you can grade it against afterward.

**You'll know it worked when** the prompt is on disk and the four beats are right there to read back:

```bash
# lh:run
cd "$(mktemp -d)"
cat > system-prompt.txt <<'EOF'
You write short satirical pieces. Structure every piece in exactly four
beats, in this order, and label nothing:

1. GRIM OPEN: state the situation at its bleakest, deadpan.
2. DARK MIDDLE: one sharp joke that sits with the bleakness.
3. THE PIVOT: introduce one true, verifiable fact that reframes it.
4. ACTIONABLE CLOSE: end with one concrete step the reader can take today.

Rules:
- The fact in beat 3 must be real and checkable. If you are unsure, omit it.
- The step in beat 4 must be something a reader could do this afternoon.
- Never explain the joke. Never use the word "hilarious".
EOF
grep -nE '^[0-9]\.' system-prompt.txt
```

```console
4:1. GRIM OPEN: state the situation at its bleakest, deadpan.
5:2. DARK MIDDLE: one sharp joke that sits with the bleakness.
6:3. THE PIVOT: introduce one true, verifiable fact that reframes it.
7:4. ACTIONABLE CLOSE: end with one concrete step the reader can take today.
```

That is real output from running the block above. Four beats, in order. If `grep` prints fewer than four lines, a beat got mangled in the paste — fix it now, before the model inherits the gap.

## Why "dark then hopeful" beats "be funny"

The arc is doing real work, not only setting a mood.

The grim open earns attention — a flat, bleak statement is more arresting than a cheerful one. The pivot on a *true fact* is what keeps the piece from being empty cynicism: it has to be something a reader could look up. And the actionable close is the payload — the reason the piece exists instead of merely venting.

Cut any one of those and you get a recognizable failure mode. No fact in beat 3 and it's nihilism with jokes. No step in beat 4 and it's a complaint. The structure isn't decoration; each beat is load-bearing.

## The part where it broke: the prompt destroys your JSON

Now you want to call the API instead of pasting into a web box. The Chat Completions endpoint wants a JSON body, and your beautiful multi-line prompt has to become one JSON string.

The obvious move is to splice the file straight into a JSON template with `printf`:

```bash
# lh:run
cd "$(mktemp -d)"
cat > system-prompt.txt <<'EOF'
You write short satirical pieces in four beats: grim open, dark middle,
a pivot on one true fact, and one concrete step the reader can take today.
Never explain the joke.
EOF
printf '{"model":"gpt-4o","messages":[{"role":"system","content":"%s"}]}\n' "$(cat system-prompt.txt)" > body-bad.json
jq . body-bad.json
```

That looks fine. It is not. Here is the real error:

```console
jq: parse error: Invalid string: control characters from U+0000 through
U+001F must be escaped at line 3, column 24
```

The newlines in your prompt are literal control characters inside a JSON string, and JSON forbids that. The API would reject this body the same way `jq` does. You'd stare at a `400` and a generic "invalid request" message, never suspecting the newline, because the prompt *looks* like text — you forgot it's now supposed to be data.

## The fix: let jq build the body

Stop assembling JSON with `printf`. The job of escaping a string for JSON belongs to a JSON tool. `jq -n` builds an object from scratch; `--rawfile` reads your prompt verbatim and escapes it correctly; `--arg` injects the per-run topic:

```bash
# lh:run
cd "$(mktemp -d)"
cat > system-prompt.txt <<'EOF'
You write short satirical pieces in four beats: grim open, dark middle,
a pivot on one true fact, and one concrete step the reader can take today.
Never explain the joke.
EOF
jq -n --rawfile sys system-prompt.txt --arg topic "the office coffee machine" '
{
  model: "gpt-4o",
  messages: [
    { role: "system", content: $sys },
    { role: "user",   content: ("Write a piece about: " + $topic) }
  ],
  temperature: 0.9
}' > body.json

jq -e . body.json > /dev/null && echo "valid: yes"
jq -r '.messages[0].content' body.json
```

```console
valid: yes
You write short satirical pieces in four beats: grim open, dark middle,
a pivot on one true fact, and one concrete step the reader can take today.
Never explain the joke.
```

That is real output. The body is valid JSON, and the system prompt round-trips with its newlines intact — `jq` turned each one into an escaped `\n` inside the string, which is exactly what JSON wants. Change the `--arg topic` value and you get a new request for a new piece; the prompt file never changes.

## Sending it

The actual API call is one `curl`. This block is documentation, not something we ran here — it needs your key and the network, so we are not pretending otherwise:

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  --data @body.json
```

Keep the key in an environment variable, never in the file or the command line. `--data @body.json` reads the body you built with `jq`, so the thing on the wire is the thing `jq` already validated.

## When this goes wrong

A few honest failure modes, in the order you'll meet them:

- **`control characters from U+0000 through U+001F`** — you went back to hand-rolling JSON. Rebuild the body with `jq -n --rawfile`. This error means a raw newline (or tab) leaked into a string.
- **The model labels the beats** ("GRIM OPEN:" appears in the output) — it's echoing your scaffolding. The prompt already says "label nothing"; if it still does, move that rule to the very end, where the model weighs it most.
- **Beat 3 invents a statistic** — the single biggest risk, and the reason for "if you are unsure, omit it." A model will happily fabricate a plausible "20% increase" with a real-sounding source. Treat every number it returns as a claim to verify, not a fact it knows. If you can't find the source, the fact is fiction.
- **Empty cynicism** — the piece is grim and funny but never pivots. Your `temperature` is doing the comedy and nothing is enforcing beats 3 and 4. Lower the temperature, or split generation: one call for the grim open, a second that's told "now add a real fact and one concrete step."

## The honest accounting

This does not make the model smarter. It makes it repeatable. The structure-in-a-file approach trades a vague request you'd have to re-explain every session for a spec you can version, diff, and grade output against.

The `jq` body-builder saves you the afternoon you'd otherwise spend on a `400` that never tells you the newline was the problem. That's the real win — not better prose, but a request that's correct the first time and the same every time after.

The fact-checking is on you. The model will produce a confident "according to the UN" out of thin air, and the prompt's "omit if unsure" rule helps but does not guarantee. Read beat 3 like a fact-checker every single time. The satire is allowed to be made up; the fact it pivots on is not.
