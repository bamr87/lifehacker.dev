---
title: "Retry only the request worth retrying: the backoff that doesn't DDoS yourself"
description: "A retry loop that hammers a 422 is a self-inflicted denial of service. Retry only 429 and 5xx, honor Retry-After, jitter the backoff, and key your POSTs."
date: 2026-09-05
preview: /images/previews/retry-only-the-request-worth-retrying-the-backoff-.svg
categories: [Hacks]
tags: [web-dev, security]
author: cass
excerpt: "The most patient attacker on your network is your own retry loop. It never sleeps, it never gives up, and it is aimed at your own server."
permalink: /hacks/retry-only-transient-failures/
---
Here is the threat nobody threat-models: the retry loop you wrote to be resilient. You added it on a Friday because a request failed once and you wanted the code to "just handle it." What you actually shipped is a small, tireless denial-of-service tool with your own credentials baked in, pointed at your own infrastructure, triggered by the exact moment your infrastructure is least able to cope. It does not phish. It does not exfiltrate. It simply asks the same broken question, faster and faster, until something falls over — and the something is usually you.

`SEVERITY: your own client library. ATTACK VECTOR: a while-loop and misplaced optimism.`

I assume every retry is hostile until proven otherwise, because the failure mode is symmetrical: a retry that helps and a retry that attacks look identical in the code. The difference is entirely in *what* you retry, *how long* you wait, and *whether the request was safe to send twice*. Get those three wrong and your resilience feature becomes the incident. The taxonomy comes straight off the [it-journey.dev API error-handling quest](https://it-journey.dev/quests/0111/error-handling/) — not every failure earns a second attempt — so let me hand you the three mitigations that matter, each one I actually ran against a deliberately hostile little server.

## First, sort the failures into "wait" and "stop"

Retrying is only ever the right move for a **transient** failure — one where the same request, sent again later, could plausibly succeed. That is a short list:

- `429 Too Many Requests` — you're rate-limited. Back off and it clears.
- `500 502 503 504` — the server or a proxy is having a moment. It may pass.

Everything in the `4xx` range *except* `429` is the server telling you the request itself is wrong: `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`. A `422` means your payload is semantically invalid — a negative amount, a missing required field, a malformed date. That request will be exactly as wrong on attempt two as it was on attempt one, and on attempt fifty. Retrying it is not resilience. It is you, personally, DDoSing an endpoint on behalf of a request that can never succeed.

So the rule the whole loop is built around: **retry `429` and `5xx`; fail fast on every other `4xx`.**

## Mitigation 1 — retry the transient, fail fast on the terminal

Here is the function. It retries only what's worth retrying, and it bails immediately — loudly — on a client error, so a bad request costs you one round trip instead of five:

```bash
# retry_request URL [MAX_ATTEMPTS]
# Retries ONLY transient failures (429, 5xx). Fails fast on other 4xx.
retry_request() {
  local url="$1" max="${2:-5}" attempt=1 base=1
  while :; do
    local body; body="$(mktemp)"
    local meta; meta="$(curl -s -o "$body" -w '%{http_code} %header{retry-after}' "$url")"
    local code="${meta%% *}" retry_after="${meta##* }"

    if [[ "$code" == 2* ]]; then
      cat "$body"; rm -f "$body"; return 0
    fi
    # Terminal: any 4xx that isn't 429. The request is wrong; stop asking.
    if [[ "$code" == 4* && "$code" != 429 ]]; then
      echo "FATAL $code (client error — not retrying): $(cat "$body")" >&2
      rm -f "$body"; return 22
    fi
    rm -f "$body"

    if (( attempt >= max )); then
      echo "GAVE UP after $attempt attempts (last=$code)" >&2; return 1
    fi

    # Backoff: honor Retry-After if present, else exponential + jitter.
    local wait
    if [[ "$retry_after" =~ ^[0-9]+$ ]]; then
      wait="$retry_after"
    else
      local exp=$(( base * 2 ** (attempt-1) ))
      local jitter=$(( RANDOM % 1000 ))          # 0..999 ms
      wait="$exp.$(printf '%03d' "$jitter")"
    fi
    echo "attempt $attempt got $code -> sleeping ${wait}s" >&2
    sleep "$wait"
    ((attempt++))
  done
}
```

I pointed it at a mock server rigged to fail on purpose: `/flaky` returns `503` twice then `200`, and `/broken` returns `422` forever. Real captured output — the `attempt … -> sleeping` lines are the function narrating itself on stderr:

```console
$ retry_request http://127.0.0.1:8811/flaky
attempt 1 got 503 -> sleeping 1.471s
attempt 2 got 503 -> sleeping 2.052s
{"ok":true,"attempts":3}

$ retry_request http://127.0.0.1:8811/broken ; echo "exit=$?"
FATAL 422 (client error — not retrying): {"error":"field 'amount' must be positive"}
exit=22
```

You'll know it worked when the transient `503` costs you three attempts and a couple of seconds, and the `422` costs you exactly one round trip and a non-zero exit code. The loop that retries the `422` is the one that shows up in someone else's incident review with your service name on it.

## Mitigation 2 — honor Retry-After, and jitter the rest

When a server sends `429`, it often tells you exactly how long to wait: a `Retry-After` header. Ignoring it and using your own backoff is the client-side equivalent of a toddler asking "are we there yet" on a fixed schedule. The function above reads the header and obeys it:

```console
$ retry_request http://127.0.0.1:8811/ratelimited
attempt 1 got 429 -> sleeping 2s
{"ok":true}
```

The server said `Retry-After: 2`, so the loop slept two seconds — not its own computed backoff — and won on the next try.

When there's no header, fall back to **exponential backoff with jitter**: `1s, 2s, 4s, 8s…`, plus a random fraction of a second on each wait. The exponent stops you from hammering; the *jitter* stops something worse. Picture the failure that took your service down: a proxy blipped and returned `503` to a thousand clients on the same tick. Without jitter, all thousand compute the same "wait 1 second," and all thousand retry on the *same next tick* — a synchronized wall of traffic slamming the server at the precise instant it's trying to recover. That's the **thundering herd**, and it's how a brief blip becomes a sustained outage. The `RANDOM % 1000` milliseconds smears those thousand retries across a full second so the server gets a drizzle instead of a tidal wave.

`SEVERITY: a coordinated botnet. ATTACK VECTOR: everyone politely retrying at once.`

## Mitigation 3 — the one that turns a timeout into a double charge

Now the part that actually costs money, and the reason I trust no retry loop near a `POST`. A `GET` is idempotent: send it twice, get the same answer, no harm. A `POST /pay` is not. And here's the trap that makes retries genuinely dangerous: your request **succeeded on the server** — the charge went through — but the response got lost on the way back, and your client saw a timeout. Your loop, seeing no `2xx`, does the reasonable thing and retries. The server, having no idea it's the same intent, charges the card again.

I ran exactly this against the mock `/pay` endpoint. Without an idempotency key, the "retry" is a brand-new charge:

```console
$ curl -s -X POST http://127.0.0.1:8812/pay
{"charge": "ch_1001", "replayed": false}
$ curl -s -X POST http://127.0.0.1:8812/pay      # the "retry"
{"charge": "ch_1002", "replayed": false}
```

Two charges. One customer. One furious email.

The fix is a **client-generated idempotency key**: a unique token you mint *once per intent* and send on every attempt of that intent. The server records the key with the result of the first success, and any later request carrying the same key gets the stored result back instead of doing the work again:

```console
$ KEY="pay-$(date +%s)-$$-$RANDOM"
$ curl -s -X POST http://127.0.0.1:8812/pay -H "Idempotency-Key: $KEY"
{"charge": "ch_1003", "replayed": false}
$ curl -s -X POST http://127.0.0.1:8812/pay -H "Idempotency-Key: $KEY"   # same key
{"charge": "ch_1003", "replayed": true}
```

Same key, same charge id, `replayed: true`. The retry became a no-op instead of a second withdrawal. Generate the key *before* the first attempt and reuse it across the whole retry sequence — a fresh key per attempt defeats the entire point, because then the server sees three intents, not three copies of one.

## When this goes wrong

- **The `503` that's really a `429` in a trench coat.** Some services rate-limit
  with `503` instead of `429`, so a "transient" retry storm is exactly what they didn't want. If a `5xx` endpoint sends a `Retry-After`, honor it — the function already does.
- **A `MAX_ATTEMPTS` with no ceiling on total time.** Five attempts of exponential
  backoff can quietly add up to 30+ seconds of a request hanging. Cap the *total* elapsed time, not just the attempt count, if a human is waiting on the other end.
- **Retrying a non-idempotent write with no key.** This is the only item on the list
  that can double-bill a customer. If you take one thing: no idempotency key, no retrying the `POST`. Send the key, or send it once and reconcile out of band.

## The payload: three mitigations, ranked

Since I distrust every retry loop, including the one I just handed you, here is the ranked list — most damage prevented first:

1. **Idempotency key on every non-idempotent retry.** This is the one that moves
   money. A lost response is not a failed request; without a key, your retry is a second charge. Mint one key per intent, reuse it across attempts.
2. **Fail fast on non-`429` `4xx`.** Never retry a request the server already told
   you is wrong. A retried `422` is a denial-of-service attack you're running against yourself, on schedule, with a clear conscience.
3. **Jittered exponential backoff, and honor `Retry-After`.** Don't be the
   thundering herd. Wait longer each time, wait a *random* amount, and when the server tells you how long to wait, believe it.

None of these is "be more careful." They're three dozen lines of shell you can run today. I did — that's the point of the console blocks. The retry loop is the call coming from inside the house; these are the three locks that keep it from robbing you.
