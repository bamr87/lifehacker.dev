---
title: "STRIDE your side project in 20 minutes: one diagram, six questions, a ranked fix list"
description: "Skip the threat-model binder: one data-flow arrow, the six STRIDE questions, a likelihood-times-impact ranking, and three fixes worth doing this week."
date: 2026-07-15
collection: hacks
author: claude
excerpt: "One data-flow arrow, the six STRIDE questions, and a sort command that hands you your three most urgent fixes."
tags: [security, threat-modeling, web]
---

Threat modeling has an image problem. Say the words and people picture a two-day workshop, a whiteboard the size of a garage door, and a 40-page document nobody reads twice. So most side projects skip it entirely and find out about their security holes the same way everyone else does: from a stranger.

There is a smaller version that fits in a coffee break. It came from the sister site's [Threat Modeling quest](https://it-journey.dev/quests/1011/threat-modeling/) — they cover the discipline properly; here is the twenty-minute field version you can actually run tonight.

The whole thing is one diagram, six questions, and a sort command. No tool to install. No binder. By the end you have a ranked list of what to fix, and — this is the part the enterprise version buries — a short enough list that you might actually fix it.

## Step 1: Draw the one arrow that matters

Forget modeling every component. Draw the smallest true picture of your app:

```text
[ you, in a browser ]  ---->  [ your app server ]  ---->  [ your database ]
                          ^
                          |
                   the trust boundary
```

A **trust boundary** is any line where data crosses from something you don't control into something you do. You control your server. You control your database. You do **not** control the browser, or the person holding it, or the network in between. So the boundary is that first arrow: the request coming in from the internet.

That arrow is where 90% of your risk lives, because it is the one place an attacker gets to send you input. The server-to-database arrow matters too, but it is inside your fence. Start at the fence.

You'll know you drew it right when you can point at exactly one arrow and say "everything on the left of this is a stranger." If you drew fifteen boxes, you're doing the enterprise version. Erase twelve.

## Step 2: Ask the six questions

STRIDE is a mnemonic for the six ways that one arrow can hurt you. Point each question **at the incoming request** and answer honestly:

- **S — Spoofing.** Can someone pretend to be a user they aren't? (Weak login, no rate limit on the login endpoint, a session token that never expires.)
- **T — Tampering.** Can someone change data they shouldn't? (No server-side validation, so the client sets fields the UI never showed them. Mass-assignment.)
- **R — Repudiation.** Can someone do a thing and later deny it, with no way to prove otherwise? (No audit log of who changed what, when.)
- **I — Information disclosure.** Can someone read data that isn't theirs? (The classic: `GET /notes/123` returns note 123 to *anyone*, not just its owner. Verbose error pages that leak a stack trace.)
- **D — Denial of service.** Can one person make it fall over? (An unbounded search query, an upload with no size cap, no rate limit anywhere.)
- **E — Elevation of privilege.** Can a normal user do admin things? (The "admin" button is hidden in the UI but the API endpoint behind it never re-checks the role.)

The trick that makes this fast: you are not brainstorming every attack in history. You are asking six fixed questions about one arrow. Twenty minutes is enough because the scope is that small.

Write down every "yes, actually" you hit. Don't fix anything yet. Fixing while you find is how you spend an hour gold-plating the first item and never reach the worst one.

## Step 3: Rank by likelihood times impact

A list of six problems isn't a plan — it's an anxiety. Turn it into a plan by scoring each finding on two axes, 1 to 3:

- **Likelihood** — how easy is this to pull off? (1 = needs a motivated attacker, 3 = a curious teenager with the browser dev tools open.)
- **Impact** — how bad if they do? (1 = mildly embarrassing, 3 = everyone's data or your whole box.)

Multiply. A 9 is a five-alarm fire; a 2 can wait. Here's a real scored pass for a typical login-plus-notes app, dumped into a file with the score in the last column. This block is opted into our test harness (`lh:run`) and runs on every build in a locked-down, no-network sandbox, so the ranking you're reading is the one the command actually produced:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

# One row per STRIDE finding:  category | the risk, in one line | likelihood*impact
cat <<'ROWS' | sort -t'|' -k3 -rn
S Spoofing        | no rate limit on /login, so credential stuffing is free | 6
T Tampering       | no server-side validation; client can set fields it should not | 4
R Repudiation     | no audit log, so "I never changed that note" is unfalsifiable | 2
I Info disclosure | GET /notes/123 returns ANY user note, not just yours (IDOR) | 9
D Denial of svc   | one client can hammer an unbounded search query | 3
E Elev. of priv   | "admin" is checked in the UI, never re-checked in the API | 6
ROWS
```

`sort -t'|' -k3 -rn` splits on the pipe, sorts on the third field, numeric, reversed — worst first. The output:

```text
I Info disclosure | GET /notes/123 returns ANY user note, not just yours (IDOR) | 9
S Spoofing        | no rate limit on /login, so credential stuffing is free | 6
E Elev. of priv   | "admin" is checked in the UI, never re-checked in the API | 6
T Tampering       | no server-side validation; client can set fields it should not | 4
D Denial of svc   | one client can hammer an unbounded search query | 3
R Repudiation     | no audit log, so "I never changed that note" is unfalsifiable | 2
```

The score isn't science. Two people will disagree by a point, and it doesn't matter — the *ordering* is what you're after, and the top and bottom sort themselves. The IDOR that leaks every user's data floats up; the missing audit log sinks. That's the whole job.

You'll know it worked when your list has a clear top. If everything scored a 6, you weren't honest about impact — a leaked note and a missing audit log are not the same fire.

## Step 4: Take the top three, ignore the rest (this week)

From that ranking, the three fixes worth your evening:

1. **The IDOR (score 9).** Add an ownership check to every fetch-by-id: `WHERE id = ? AND owner_id = ?`, not just `WHERE id = ?`. One clause. Biggest single win here.
2. **The login rate limit (score 6).** Cap attempts per IP/account. A ten-tries-then-cool-off is enough to make credential stuffing uneconomical.
3. **The server-side admin check (score 6).** Re-check the role in the API handler, not only in the template that hides the button. The UI is a suggestion; the API is the gate.

The bottom three are real, and you should get to them — but "this week" holds three items, not six. A threat model you half-finish because it was too big is worth less than three fixes you actually shipped.

## When this goes wrong

Two honest failure modes, because leaving them out is how the enterprise binder got so long:

- **You model the wrong arrow.** Teams spend the whole session on the server-to-database link — encryption at rest, connection pooling — because it feels technical. But that arrow is inside your fence. If an attacker is already on your server reading the DB connection, the game was lost one arrow earlier. Spend your twenty minutes on the boundary the stranger can actually reach.
- **You confuse "I scored it" with "I fixed it."** The ranked list is a to-do, not a shield. A beautiful STRIDE table sitting next to a live IDOR has protected exactly nobody. The output of this exercise is three code changes, not a document.

And the reason this beats the fancy modeling tool with the drag-and-drop canvas and the STRIDE auto-suggester: you'll open that tool once, admire it, and never launch it again. A diagram you can draw on a napkin and a sort command you already have installed are the version you'll still be running next quarter. The best threat model is the one you actually run twice.

Twenty minutes. One arrow. Six questions. Go find your 9.
