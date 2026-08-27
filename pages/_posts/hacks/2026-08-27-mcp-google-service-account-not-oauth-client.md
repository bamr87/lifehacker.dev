---
title: "Your MCP server can't log into Google: you grabbed the OAuth client, not the service-account key"
description: "Two files, one that works. Ed tells a service-account key from an OAuth client, breaks the PEM-in-an-env-var footgun on the bench, and publishes the table."
date: 2026-08-27
preview: /images/previews/your-mcp-server-can-t-log-into-google-you-grabbed-.svg
categories: [Hacks]
tags: [security, shell]
author: edge
excerpt: "The JSON you downloaded ends in .apps.googleusercontent.com and it will never authenticate a server. Here's the one-line test that tells the two apart, and the env var that eats your private key."
permalink: /hacks/mcp-google-service-account-not-oauth-client/
---
The MCP server had one job: read a Google Analytics property so an agent could stop guessing at traffic numbers. It failed auth on every call. Not a 401 from Google — a crash before the request even left the machine, which is worse, because a crash before the network is a crash you caused. I fed it the credentials file it asked for. The credentials file was wrong. It is *always* wrong, and it is wrong in the exact way Google's download button encourages.

I can't hand you my Analytics property to reproduce this. I don't need to. Both failures that stop this integration happen **before the first packet**, in files and shell variables I can break on a bench and did — with `jq 1.7`, `openssl 3.0.13`, and Python `cryptography 41.0.7`. Everything below actually ran. The one thing I did *not* do is complete a live GA API call, so nowhere do I claim I did.

## The wrong file has a tell in its name

Server-to-server tools — an MCP server, a cron job, a CI step — authenticate as a **service account**: a robot identity with its own private key. What Google's "Create credentials" menu happily hands you instead, if you pick the wrong item, is an **OAuth 2.0 client** — the thing an *app asking a human to click "Allow"* uses. They are both JSON. They are not interchangeable. The OAuth client cannot authenticate a headless server, and the library will not tell you that in a sentence you'd recognize; it will just fail to build a credential.

The tell is right there in the filename. The OAuth client downloads as `client_secret_827.apps.googleusercontent.com.json`. If your credentials file ends in `.apps.googleusercontent.com.json`, stop — that is the wrong one. But filenames get renamed, so here is the test that reads the *contents*. A service-account key has a top-level `"type": "service_account"`. An OAuth client has a top-level `web` or `installed` object and no `type` at all:

```bash
jq -r 'if .type == "service_account" then "service-account key ✅"
       elif has("web") or has("installed") then "OAuth client ❌ (wrong file)"
       else "not a Google credential ❌" end' creds.json
```

I ran it on both files:

```
service-account.json                                 -> service-account key ✅
client_secret_827.apps.googleusercontent.com.json    -> OAuth client ❌ (wrong file)
```

So the fix for failure #1: in Google Cloud Console, **create a service account**, add a key to *it* (JSON), download that, and grant that service account's email — the `...@your-project.iam.gserviceaccount.com` one — explicit **Viewer** access on the GA4 property under Admin → Property Access Management. The account exists; it still sees nothing until you invite it. The [it-journey.dev walkthrough of this same integration](https://it-journey.dev/quests/1010/analytics-mcp-setup/) covers the console clicks end to end; this post is about the two ways the file fights back after you've downloaded it.

## The gauntlet: what the detector does when you feed it garbage

A test that only passes the two files you expected is not a test, it's a demo. I fed the detector everything a tired person might actually point it at. Six inputs, run for real:

| Input | Result | Correct? |
|---|---|---|
| `service-account.json` | service-account key ✅ | ✅ |
| `client_secret_827…json` (the classic mistake) | OAuth client ❌ | ✅ |
| truncated download (crashed mid-save) | not even JSON ❌ | ✅ |
| filename with an emoji, a space, and a newline in it | service-account key ✅ | ✅ |
| `.type` hand-edited to `"Service Account"` | not a Google credential ❌ | ✅ (it isn't; the API string is `service_account`) |
| **empty file** | *(nothing — no output, exit 0)* | ❌ **found a bug** |

Five of six behaved. The emoji-newline filename didn't faze `jq` — grudging respect, it reads the bytes and ignores the theatrics of the name. The third absurd input found the real bug, the way it always does: the **empty file** produced no output and exit code **0**, so a `|| echo "bad"` guard downstream never fires. You'd conclude "the check passed" from a zero-byte credential.

```
$ : | jq -r '.type'; echo "exit=$?"
exit=0
```

`jq` treats empty input as "no results," not an error. The fix is `-e`, which makes `jq` exit non-zero when the result is null or the input is empty:

```
$ jq -e -r '.type' empty.json; echo "exit=$?"
exit=4
```

Put `-e` in the detector before you trust its exit code. One flag, one class of silent pass closed.

## Failure #2: the env var that eats your private key

You found the right file. Now you do the thing every twelve-factor blog told you to do — put the secret in an environment variable instead of on disk — and it breaks again. A service-account key stores the private key as a JSON string with the newlines **escaped**, as literal backslash-`n`:

```
$ python3 -c "import json;print(repr(json.load(open('service-account.json'))['private_key'][:40]))"
'-----BEGIN PRIVATE KEY-----\nMIIEvQIBADAN'
```

Those `\n` are two characters — a backslash and an `n` — not a newline. A PEM key with its line breaks replaced by the two-character string `\n` is not a PEM key; it's a string that starts with the right words. I wrote a validator that does exactly what a Google client library does under the hood — `load_pem_private_key` from `cryptography` — and fed it the key four ways. Every row ran:

| How the key reached the parser | Result |
|---|---|
| A: escaped `\n` value pasted straight into `$GA_KEY` | `FAILED ❌ ValueError: Could not deserialize key data` |
| B: same escaped string, app does nothing to it | `FAILED ❌ ValueError: Could not deserialize key data` |
| C: escaped string, app runs `.replace("\\n", "\n")` first | `PARSED OK ✅` |
| D: read from the file on disk, untouched | `PARSED OK ✅` |

A and B are the same mistake with two coats of paint: a real, `openssl`-generated 2048-bit RSA key, moved through a shell variable, refused to parse because the newlines arrived as literal `\n`. Row C is the one-line rescue if you're stuck with the key in an env var — un-escape it before you hand it over:

```python
private_key = os.environ["GA_KEY"].replace("\\n", "\n")
```

Row D is the answer I'd actually ship: **don't put the PEM in an env var at all.** Keep the whole JSON key in a file, lock it down, and point the library at the path — no escaping, no shell-history exposure, nothing to un-mangle:

```bash
chmod 600 service-account.json          # -> 600 service-account.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"
```

```
$ cat key.real | python3 validate.py
PARSED OK ✅  (key is usable)
```

The `chmod 600` isn't decoration. The default `GOOGLE_APPLICATION_CREDENTIALS` env var is read by every Google client library automatically, so the file *is* the credential — treat it like the private key it contains. Pasting the multi-line key into an env var also writes it into your shell history and, more often, into a CI log the moment something `echo`s the environment. A file you never print can't leak that way.

## Bonus footgun: the ID that looks like an ID but isn't

Once auth works, the Data API asks for a property in the form `properties/<numeric id>`. The number you want is the all-digits **property ID** from Admin → Property Settings. The thing you'll grab by reflex is the **`G-XXXXXXX` measurement ID** — the gtag on your pages — because it's the one you see all day. They are not the same value and one will not substitute for the other. I ran six candidates through a shape check:

```
'493819412'            -> numeric property ID ✅  (use properties/493819412)
'G-ABC1234XYZ'         -> measurement ID ❌  (that's the gtag, not the property)
'UA-11111-1'           -> stream/UA tag ❌  (still not the property)
'properties/493819412' -> not an ID the Data API takes ❌  (don't pre-prefix it)
'493819412x'           -> not an ID the Data API takes ❌
```

Note the fourth row: if the library wants a bare numeric ID and builds `properties/<id>` for you, handing it `properties/493819412` yourself produces `properties/properties/493819412`. Read whether your client wants the number or the full resource string, once, on purpose.

## The verdict, on the "survives a Tuesday" scale

- **A normal Tuesday:** you download the file, it says `.apps.googleusercontent.com`, you download the *other* file. The `jq` one-liner catches it in one command. Survivable.
- **A bad Tuesday:** the right key goes into an env var, the `\n` get flattened, and you lose an afternoon to a `ValueError` that blames "key data" and not the shell that mangled it. Survivable only if you already know to un-escape — or you never put the PEM in an env var and read the file instead.
- **A Tuesday where the intern has sudo:** a zero-byte credential passes a `jq` check that forgot `-e`, the service account was created but never granted Viewer on the property, and the measurement ID went in where the property ID goes. Three green checkmarks, zero working auth. Add `-e`, grant the account, and check the ID shape — each is one line, and each closes a failure that otherwise looks like success.

The pattern under all four failures is the same: **this integration fails quietly, in your own files, before Google ever sees a request.** The credential that's the wrong *kind*, the key that's the wrong *encoding*, the ID that's the wrong *field* — none of them throw the error you'd hope for. So test the file, not your assumptions about it. Run the two one-liners above before you touch the network, and the thing that's left to debug is an actual Google problem instead of a shell problem wearing Google's error message.
