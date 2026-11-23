---
title: Natas
description: "Natas teaches server-side web security through 35 browser-based levels, from reading page source to SQL injection, session attacks and cryptographic oracles."
excerpt: "Natas teaches server-side web security through 35 browser-based levels, from reading page source to SQL injection, session attacks and cryptographic oracles."
permalink: /docs/wargames/natas/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-10-16T22:41:14.000Z'
categories:
- wargames
- natas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/index.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- natas
author: bamr87
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Natas
=====

Natas teaches the basics of serverside web-security.

Each level of natas consists of its own website located at **http://natasX.natas.labs.overthewire.org**, where X is the level number. There is **no SSH login**. To access a level, enter the username for that level (e.g. natas0 for level 0) and its password.

Each level has access to the password of the next level. Your job is to somehow obtain that next password and level up. **All passwords are also stored in /etc/natas\_webpass/**. E.g. the password for natas5 is stored in the file /etc/natas\_webpass/natas5 and only readable by natas4 and natas5.

Start here:

    Username: natas0
    Password: natas0
    URL:      http://natas0.natas.labs.overthewire.org


Tools you may find useful to solve this wargame
-----------------------------------------------

A webbrowser, curl, ZAP proxy

<div style="float: right; text-align: center">
<a href="http://www.nessos-project.eu/"><img alt="FP7 NESSOS" src="https://overthewire.org/wargames/natas/FP7-NESSOS.jpg"></a><br/>
developed in association with<br/> the <a href="http://www.nessos-project.eu/">NESSoS FP7 project</a>
</div>

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This guide is spoiler-free: it names the concept each level exercises so you know what to study, but it never gives passwords, payloads or finished solutions.

### What Natas teaches

Natas is a tour of how web applications fail. There is no SSH login. Each level is its own website at `natasN.natas.labs.overthewire.org`, protected by HTTP Basic authentication (a browser pop-up asking for a username and password). Your job is to make the site disclose the password for the next level. Along the way you meet most of the classic web vulnerabilities, always from the server side: the flaws are in how the *server* trusts what the browser sends.

### How the levels are numbered

Unlike Bandit, the page for Level N is the level you are *in*: sign in as `natasN` and look for the password to `natasN+1`. Every level's password is also stored on the server in `/etc/natas_webpass/`, readable only by that level's user and the previous one, which is the file the vulnerabilities in later levels aim to read.

### The learning path

| Levels | Theme | Core ideas |
|--------|-------|-----------|
| 0–3 | Information disclosure | page source, hidden resources, directory listings, `robots.txt` |
| 4–7 | Trusting the client | request headers, cookies, source disclosure, file inclusion |
| 8–11 | Encodings and weak crypto | reversing an encoding, command injection, XOR |
| 12–13 | File upload | trusting filenames and file signatures |
| 14–17 | SQL injection | authentication bypass, blind and time-based extraction |
| 18–21 | Sessions | predictable IDs, custom session handling, shared state |
| 22–25 | PHP behaviour | redirects, loose comparison, filters and log files |
| 26–28 | Deeper flaws | object deserialization, truncation, block-cipher misuse |
| 29–33 | Perl and PHP internals | injection through language features, uploads, phar |
| 34 | The end (for now) | consolidate and move on |

### Tools you need

- **A browser with developer tools.** View source, the Network tab (to see requests, headers and cookies) and the cookie viewer cover the first third of the game.
- **`curl`.** Sends exactly the request you specify, which is how you control headers, cookies and methods. Run `curl -u natasN:PASSWORD URL`.
- **An intercepting proxy** such as OWASP ZAP or Burp Suite for editing requests in flight.
- **A scripting language.** Python with `requests` is ideal from the blind-injection levels onward, where you automate hundreds of requests.

### How to approach any web level

1. Use the app as a normal user and note every input: form fields, URL parameters, cookies, headers, uploaded files.
2. Read all the client-side code and the page source, and follow every link and referenced resource.
3. When source code is offered, read it as a defender: what does the server assume about each input?
4. Form a hypothesis, test it with the smallest possible request, and read the response closely.

### Staying on the right side of the line

Everything here is meant to be attacked, but only the Natas servers. Never apply these techniques to websites you do not own or have written permission to test.

<nav class="sg-nav" aria-label="Level navigation"><span></span><span></span><a class="sg-next" href="natas0/">Start at Level 0</a></nav>

</section>

<!-- study-guide:end -->
