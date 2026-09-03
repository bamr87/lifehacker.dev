---
title: "Retire an API endpoint without the 404 ambush: Deprecation, Sunset, and 410 Gone"
description: "A deleted endpoint that returns 404 tells callers they typed it wrong, so they retry forever. Sunset it in the open with Deprecation/Sunset/Link and 410 Gone."
date: 2026-09-03
preview: /images/previews/retire-an-api-endpoint-without-the-404-ambush-depr.svg
categories: [Hacks]
tags: [web-dev, security]
author: cass
excerpt: "404 says 'you typed it wrong.' 410 says 'this is gone on purpose.' The gap between them is where zombie endpoints and retry storms live."
permalink: /hacks/retire-api-endpoint-sunset-410-gone/
---
Here is the threat nobody threat-models: the endpoint you already deleted. Not the one you're building — the one you removed last quarter, deleted the handler for, took out of the docs, and mentally filed under "gone." I assume it is still answering. I assume there is a cron job in a datacenter you've never heard of, owned by a team that left the company, calling `POST /v1/charge` every ninety seconds, and I assume it will keep calling until the heat death of the universe or your next incident, whichever comes first.

The reason it keeps calling is a status code. When you rip an endpoint out and let the framework's default catch-all answer the request, that caller gets a `404 Not Found`. And `404` does not mean "this is gone." `404` means **"you typed it wrong."** It is the HTTP equivalent of a shrug. Every well-written client treats a 404 as a transient, possibly-my-fault condition and does the most reasonable, most catastrophic thing available: it retries. The lesson comes straight off the [it-journey.dev API versioning quest](https://it-journey.dev/quests/0111/api-versioning/) — retiring a version is a protocol, not a delete key — so let me hand you the protocol, and then the two ways it quietly betrays you.

## 404 says "you're wrong." 410 says "I'm gone." Say the true one.

`410 Gone` is the status code for intentional, permanent removal. It exists precisely so a server can tell a client "stop asking, this is never coming back, update your code" instead of "hmm, weird, try again." I spun up a fifteen-line server that retires an endpoint the honest way, and here is the difference on the wire — real output from `curl -sD - -o /dev/null`, which prints the response headers and throws the body away:

```console
$ curl -sD - -o /dev/null http://127.0.0.1:8771/typo/widgets
HTTP/1.1 404 Not Found
Content-Type: application/json
Content-Length: 21

$ curl -sD - -o /dev/null http://127.0.0.1:8771/legacy/widgets
HTTP/1.1 410 Gone
Content-Type: application/json
Link: </v2/widgets>; rel="successor-version"
Content-Length: 36
```

Same shape, opposite meaning. The 404 is a route that never existed — a real typo. The 410 is a route that existed, served, and was retired on purpose, and it carries a `Link` header pointing at where the widgets went. A client that reads status codes will stop retrying the 410 and follow the successor. A client that got a 404 will still be trying at 3 a.m. You will know it worked when your access log stops showing repeated hits on the dead path, because well-behaved callers actually give up on a 410.

`SEVERITY: your own past self. ATTACK VECTOR: the default 404 handler that turns "we removed this" into "keep trying."`

## The overlap window: deprecate loudly *before* you sunset

You do not go from 200 to 410 on a Friday. There is an overlap window where both the old and new versions run, and during it the old endpoint's job is to be a working endpoint that will not shut up about its own mortality. Three response headers do that, and the [`Deprecation` / `Sunset` RFCs](https://www.rfc-editor.org/rfc/rfc9745.html) are the standard for them — not homemade JSON fields that nobody's client library reads:

```console
$ curl -sD - -o /dev/null http://127.0.0.1:8771/v1/widgets
HTTP/1.1 200 OK
Content-Type: application/json
Deprecation: true
Sunset: Sat, 01 Nov 2025 00:00:00 GMT
Link: </v2/widgets>; rel="successor-version"
Content-Length: 29
```

`Deprecation: true` says "this still works, but it is on its way out." `Sunset:` gives the date it dies, in the same HTTP-date format as `Expires` — a machine-readable deadline a monitoring job can alert on. `Link: …; rel="successor-version"` names the replacement so a client can find v2 without reading your changelog, which it will not read. The endpoint returns a normal 200 with a normal body the whole time. The difference is that a caller who logs response headers — and a paranoid caller logs response headers — now has a countdown and a forwarding address months before anything breaks.

The part where this goes wrong: nobody reads response headers on the happy path. So the headers are necessary but not sufficient. Send an email, open a ticket against the calling team, and — the move that actually works — watch the access log to see *who is still calling the deprecated route*, then go tell those specific humans. Headers inform the diligent; the log finds the ones who aren't.

## The convenience feature that hides your callers: header-based versioning

Here is where my tinfoil goes back on. There's a school of API design that versions by content negotiation instead of by URL: same path, and the client asks for a version in the `Accept` header. It's elegant. It keeps your URLs clean. It is also, from a "who is about to be broken by my sunset" standpoint, an information-hiding attack you carried out against yourself.

```console
$ curl -s http://127.0.0.1:8771/widgets
{"version":"v1","widgets":[]}
$ curl -s -H 'Accept: application/vnd.api.v2+json' http://127.0.0.1:8771/widgets
{"version":"v2","widgets":[]}
```

Same URL. Two versions. Your access log records the path, and the path is identical, so **your log cannot tell you which callers are on v1 and which are on v2.** The one signal you needed to safely retire v1 — who is still using it — is the exact signal this design negotiated into a request header your log throws away. Convenience is an attack surface with better marketing, and this one attacks your ability to see.

And it gets worse, because a response that varies by a request header is a cache-poisoning setup unless you say so. The correct server sets `Vary: Accept`, which tells every shared cache "key on the Accept header, these are different responses." Leave it out and a naive cache keys on the URL alone. Watch a deliberately-naive caching proxy do the crime — the v1 client fills the cache, and then the v2 client asks the same URL and gets served v1:

```console
$ curl -s -D - http://127.0.0.1:8772/widgets | grep X-Cache
X-Cache: MISS
$ curl -s http://127.0.0.1:8772/widgets
{"version":"v1","widgets":[]}

$ curl -s -D - -H 'Accept: application/vnd.api.v2+json' http://127.0.0.1:8772/widgets | grep X-Cache
X-Cache: HIT
$ curl -s -H 'Accept: application/vnd.api.v2+json' http://127.0.0.1:8772/widgets
{"version":"v1","widgets":[]}
```

The v2 client asked for v2, got a cache HIT, and received v1 — because the cache never knew the `Accept` header mattered. Now imagine v1 and v2 have different auth scopes, or v1 leaks a field v2 redacts. That is no longer a versioning bug. That is a data-exposure bug wearing a versioning bug's clothes.

## The three mitigations that actually matter

**One — return 410 Gone for retired routes, and keep the tombstone.** The single highest-value change: don't let the default 404 handler answer for endpoints you removed on purpose. Return `410` with a `Link: rel="successor-version"` so clients stop retrying and know where to go. Keep the tombstone route in your codebase — a deleted route that reverts to a silent 404 is a route that starts lying again the day someone cleans up "dead code." I ran both above; the 410 is four lines of handler and it is the difference between "clients migrated" and "clients retry forever."

**Two — sunset on the standard headers, then hunt the stragglers in the log.** During the overlap window, serve `Deprecation: true`, a `Sunset:` date in HTTP-date format, and the successor `Link`. Then — because nobody reads headers on the happy path — grep your access log for the deprecated path (or, if you versioned by header, for the deprecated `Accept` value, assuming you had the foresight to log it) and go find the humans still calling it. The headers are for the diligent; the log is for everyone else.

**Three — if you version by header, set `Vary: Accept`, and log the Accept header.** Content negotiation is fine right up until it makes your callers invisible and your caches wrong. `Vary: Accept` on every negotiated response is non-negotiable — I showed you the cache serving v1 to a v2 client without it. And add the `Accept` (or your version header) to your access log format on day one, because the day you want to sunset v1 is the day you'll wish you could see who's on it, and by then it's too late to start collecting.

Retiring an endpoint is not a delete key. It's a supervised handoff with a paper trail, a deadline, and a forwarding address — and the whole reason to do it in the open is that the alternative is a 404 that quietly trains every client you have to retry a corpse. Assume the corpse is still being called. Then go check the log and prove yourself wrong.
