---
title: "mkcert: the one-command HTTPS fix that hands you a root CA for every domain on earth"
description: "mkcert makes trusted localhost HTTPS in one command. It does that by installing a root CA that will sign any domain at all. Threat-modeled and tested on v1.4.4."
date: 2026-11-26
preview: /images/previews/mkcert-the-one-command-https-fix-that-hands-you-a-.svg
categories: [Tools]
tags: [system]
author: cass
verdict: "Use it for local HTTPS. Trust its CA only in the process that needs it, uninstall and delete the CA when the project ends, and never copy rootCA-key.pem anywhere."
excerpt: "One command and the browser's red padlock goes green. The cost of that convenience is a homemade certificate authority that will vouch for github.com without blinking, sitting in a file in your home directory."
permalink: /tools/mkcert-honest-review/
---
**Verdict: use it, carefully. `mkcert` gives you real, browser-trusted HTTPS on `localhost` in one command, and it does exactly what it says. What it says is this: it creates your own certificate authority and, if you run `-install`, adds it to your machine's trust store. That CA has no limit on which names it can sign for. I had it issue a certificate for `github.com`, and after `-install` my test machine accepted a server I made up as the real thing. The tool isn't broken. That is what a root CA is. Below is what I ran, what it trusted, and the three habits that keep a dev convenience from becoming a skeleton key.** I have no relationship with mkcert or its author. It's BSD-3-Clause licensed (checked against GitHub's API, not the README, because the README is the part an attacker would edit), and nobody paid me.

Nobody threat-models the green padlock. You see it and stop thinking, and that's what it's for. Now picture the escalation. A developer runs one friendly command to get rid of a browser warning. Their laptop now trusts a CA whose private key is a 2,484-byte file in `~/.local/share/mkcert`. That file gets synced to a backup service, the backup service gets popped, and a three-letter agency with a taste for irony is serving you a counterfeit login page signed by *your own* CA. The padlock is green the whole time, because you told it to be. Back to reality: nobody is running that operation against your side project, and mkcert's own README warns about the key in bold. The realistic risk is duller: a forgotten CA that still trusts everything it ever signed, on a laptop that outlives the project by three years. That's still worth ten minutes.

`SEVERITY: you, two years ago. ATTACK VECTOR: a file you forgot you made.`

Everything below ran for real with `mkcert v1.4.4` (the Linux amd64 release binary) on Ubuntu 26.04. The trust-store tests (`-install`, `-uninstall`) ran as root inside a throwaway `debian:bookworm-slim` container, so the test runner's own trust store never changed. I pointed `CAROOT` at a scratch directory so the CA lived somewhere I could throw away. The `exit=` lines in the output come from an `echo "exit=$?"` I ran after each command, not from mkcert or curl. I've kept the `runner@…` hostname that mkcert stamps into every certificate, because the CA puts your username and machine name in every cert it issues. Remember that if you ever hand one of these certs to someone.

## What earns the install

The pitch is real. One command makes a CA and a certificate:

```console
$ mkcert localhost 127.0.0.1 ::1
Created a new local CA 💥
Note: the local CA is not installed in the system trust store.
Note: the local CA is not installed in the Firefox and/or Chrome/Chromium trust store.
Note: the local CA is not installed in the Java trust store.
Run "mkcert -install" for certificates to be trusted automatically ⚠️

Created a new certificate valid for the following names 📜
 - "localhost"
 - "127.0.0.1"
 - "::1"

The certificate is at "./localhost+2.pem" and the key at "./localhost+2-key.pem" ✅

It will expire on 26 February 2029 🗓
```

The emoji are mkcert's. I'm reporting them, not endorsing them. The defaults are good. The leaf key was written `0600` and the CA key `0400` (read-only, owner only). The leaf certificate lasts about 27 months, not forever. It says plainly that it hasn't touched any trust store yet. Compare that with a weekend spent on `openssl req -x509 -newkey ...` and a config file full of `subjectAltName` lines you copied from Stack Overflow, and it's an easy win. The certificate also has the SANs (Subject Alternative Names) browsers actually check:

```console
$ openssl x509 -in localhost+2.pem -noout -subject -issuer -enddate -ext subjectAltName
subject=O=mkcert development certificate, OU=runner@runnervm0hi8g
issuer=O=mkcert development CA, OU=runner@runnervm0hi8g, CN=mkcert runner@runnervm0hi8g
notAfter=Feb 26 23:02:39 2029 GMT
X509v3 Subject Alternative Name: 
    DNS:localhost, IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1
```

## The part where it signs github.com

Now the root itself:

```console
$ openssl x509 -in "$(mkcert -CAROOT)/rootCA.pem" -noout -startdate -enddate
notBefore=Nov 26 23:02:38 2026 GMT
notAfter=Nov 26 23:02:38 2036 GMT
$ openssl x509 -in "$(mkcert -CAROOT)/rootCA.pem" -noout -text | grep -A1 -E "Basic Constraints|Key Usage"
            X509v3 Key Usage: critical
                Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
```

It's a ten-year root. `pathlen:0` stops it from creating sub-CAs, which is good. There's no `Name Constraints` extension in that output, so nothing restricts it to `localhost` or `*.test`. It can sign any name, and it does:

```console
$ mkcert github.com "*.google.com"
Reminder: X.509 wildcards only go one level deep, so this won't match a.b.google.com ℹ️

The certificate is at "./github.com+1.pem" and the key at "./github.com+1-key.pem" ✅

It will expire on 26 February 2029 🗓

$ openssl verify -CAfile "$(mkcert -CAROOT)/rootCA.pem" github.com+1.pem
github.com+1.pem: OK
```

It gave a helpful note about wildcard depth and no warning about the domain. To be fair, this isn't a bug. mkcert is a CA, and refusing real domains would break legitimate uses such as testing your production hostname locally. The README says it directly: *"the `rootCA-key.pem` file that mkcert automatically generates gives complete power to intercept secure requests from your machine. Do not share it."* So I tested what "complete power" looks like. Inside the container I served that `github.com` certificate with `openssl s_server` on `127.0.0.1:8443`, used curl's `--resolve` to point `github.com` at it, and tried it before and after `-install`:

```console
$ curl -s -o /dev/null -w "%{http_code}\n" --resolve github.com:8443:127.0.0.1 https://github.com:8443/
000
exit=60
$ mkcert -install
The local CA is now installed in the system trust store! ⚡️

$ curl -s -o /dev/null -w "%{http_code}\n" --resolve github.com:8443:127.0.0.1 https://github.com:8443/
200
exit=0
$ ls /usr/local/share/ca-certificates/
mkcert_development_CA_214303625599258753040507832062200318509.crt
```

Before `-install`, curl refused it (exit 60, certificate problem). After, a process on my machine pretending to be github.com got a clean `200`. On that machine, the private key file and a way to redirect traffic are all an attacker needs. Every convenience is an attack surface with better marketing, and this one's marketing is a green padlock.

## The part where uninstall doesn't mean gone

```console
$ mkcert -uninstall
The local CA is now uninstalled from the system trust store(s)! 👋

$ curl -s -o /dev/null -w "%{http_code}\n" --resolve github.com:8443:127.0.0.1 https://github.com:8443/
000
exit=60
$ ls -l "$(mkcert -CAROOT)"
total 8
-r-------- 1 1001 1001 2484 Nov 26 23:03 rootCA-key.pem
-rw-r--r-- 1 1001 1001 1655 Nov 26 23:03 rootCA.pem
```

`-uninstall` does what its help text promises, "Uninstall the local CA (but do not delete it)." Trust is removed and the key stays. That's a reasonable design: you can re-install later without re-issuing every cert. But it means the dangerous file outlives the step most people think of as cleanup. (I only tested the system store. Firefox and Java keep their own stores, which mkcert also writes to when it detects them. The `TRUST_STORES` variable picks which ones.)

## The three mitigations that matter

I ran each of these in the sandbox above, ranked by how much risk they remove.

**1. Trust per process, not per machine: skip `-install` when you can.** Most dev HTTPS problems involve one client: curl, a test suite, a Node script. Give that client the CA directly and the rest of the machine never trusts it. Same server, same fake github.com cert, no `-install`:

```console
$ curl -s -o /dev/null -w "%{http_code}\n" --cacert "$(mkcert -CAROOT)/rootCA.pem" --resolve github.com:8443:127.0.0.1 https://github.com:8443/
200
exit=0
```

Plain `curl` still failed with exit 60. Only the command that asked for the CA trusts it. For Node, the mkcert README documents `NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"`, because Node ignores the system store anyway. I didn't run a Node test, so treat that one as documented, not tested. You only need `-install` for a real browser, and then mitigation 2 matters more.

**2. When the project ends, uninstall and delete.** Removing trust takes two steps, and the second is the one people forget:

```bash
mkcert -uninstall
rm -rf "$(mkcert -CAROOT)"
```

The output above shows that `-uninstall` alone made curl refuse the fake github.com again (exit 60) and left `rootCA-key.pem` on disk. Deleting it is what retires the key. Better still, set `CAROOT` per project (mkcert supports separate CAs this way) so each CA is only as old as the thing it's for, and deleting the project directory takes the key with it. Whatever you do, keep that directory out of git, Docker build contexts and synced folders.

**3. Phones and other devices get the certificate, never the key.** To test on a phone you install the root there too, and the shortcut is to copy the whole CAROOT folder. Don't. I gave a second CAROOT only `rootCA.pem`:

```console
$ CAROOT=/phone mkcert -install
The local CA is now installed in the system trust store! ⚡️

exit=0
$ CAROOT=/phone mkcert example.test
ERROR: can't create new certificates because the CA key (rootCA-key.pem) is missing
exit=1
```

The device trusts certs from your dev machine but can't issue any. If that device is lost, a stranger gets your trust settings, not your signing key. The README says the same thing for mobile: install `rootCA.pem`. It never mentions the key.

## Bottom line

mkcert is the right answer to "I need HTTPS on localhost," and it's honest about what it does. The private key is read-only by default, the README warns about it in bold, and nothing is trusted until you run `-install`. The risk is in how people use it. The CA it installs has no name constraints, lasts ten years, and stays on disk after `-uninstall`, so a tool you ran once becomes a root that can impersonate any site to your own machine. Pass the CA to the process that needs it, uninstall and delete it when you're done, and copy only the `.pem` without `-key` in its name. Source and docs: [github.com/FiloSottile/mkcert](https://github.com/FiloSottile/mkcert).
