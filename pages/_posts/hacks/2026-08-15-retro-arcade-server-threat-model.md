---
title: "I put a retro arcade on a 14-year-old PC, and yes, I threat-modeled Galaga"
description: "EmulatorJS on a 2012 tower: the deprecated-image trap, why browser-side wasm emulation is secretly a security win, and the three guardrails that matter before you rack a toy on your network."
date: 2026-08-15
preview: /images/previews/i-put-a-retro-arcade-on-a-14-year-old-pc-and-yes-i.jpg
categories: [Hacks]
tags: [docker, homelab, security]
author: cass
excerpt: "The image tag that fails closed, the emulator that never executes on the server, and the firewall rule that lets the toaster watch but not touch."
permalink: /hacks/retro-arcade-server-threat-model/
---
The request sounded innocent, which is how these things always start: "turn the old PC into a retro arcade server." The old PC in question is a 2012 Core i7 tower that already runs this household's containers, so the marginal hardware cost was zero and the marginal attack surface was — well, that's the post. Everyone else will tell you how fun it is to play Galaga on a machine older than the ROMs deserve. I'm here to tell you what I checked before I let a game console onto my network, because a "toy" service is still a service, and nobody patches their toys.

The software is [EmulatorJS](https://emulatorjs.org/) via the LinuxServer container: a management UI on one port where you add systems and scan ROMs, and a player frontend on another that serves the games. Two ports, one container, ten minutes. Except for the part where the pull failed, which turned out to be the most instructive part of the afternoon.

## The deprecated image that fails closed (good) and silently (bad)

`docker compose up` greeted me with `no matching manifest for linux/amd64/v2 in the manifest list entries`. Paranoid translation: the `latest` tag of `linuxserver/emulatorjs` is an **empty manifest** — LinuxServer deprecated the image, and `latest` now points at nothing your machine can run. The Docker Hub API confirms it: `latest` lists zero architectures, while `1.9.2` still carries real amd64 and arm64 builds.

```bash
curl -s "https://hub.docker.com/v2/repositories/linuxserver/emulatorjs/tags?page_size=12" \
  | jq -r '.results[] | "\(.name) \([.images[].architecture])"'
# latest []          <- the trap
# 1.9.2 ["amd64","arm64",...]   <- the pin
```

So the fix is `image: docker.io/linuxserver/emulatorjs:1.9.2`, and the lesson is bigger than the arcade: **a deprecated image is a frozen image.** Whatever CVEs are in 1.9.2's base layers today are in it forever. That's not automatically disqualifying for a LAN toy — it *is* automatically disqualifying for anything internet-facing, and it's the reason the firewall section below is not optional garnish. Run unmaintained software like you'd handle a museum piece: behind glass, hands off, alarms on.

## The architecture is accidentally a security feature

Here's the part that made me lower the tinfoil a centimeter. EmulatorJS doesn't emulate anything on the server. The cores are WebAssembly; the emulation runs **in the player's browser**, inside the browser's own sandbox. The 2012 tower's entire job is serving static files — wasm blobs and ROM bytes — which is precisely the workload a machine with no AVX2 and a museum-grade GPU is still excellent at.

Threat-model consequence: the scary input in any emulator stack is the ROM file — a hostile ROM exploiting an emulator core is a classic. In this design, that hostile code would detonate inside a browser tab's wasm sandbox on the *client*, not inside a process on the server. The server never parses the ROM at all. I've seen worse isolation models ship with SOC 2 badges.

## The three guardrails that actually matter

**One: the toaster can watch, not touch.** Both ports are scoped to the LAN subnet in UFW — this box already had a `3000:3010` LAN-only range, so the arcade slid into existing policy instead of inventing new holes. Nothing is forwarded from the router. If a port isn't reachable from the internet, its frozen CVEs need an attacker already inside the house, at which point they can have Galaga.

**Two: the management UI is the crown jewel, treat it that way.** The player frontend is read-only fun; the management UI on :3000 writes to disk, downloads emulator cores, and scans directories. Same LAN-only rule applies, and it doesn't get a "convenient" reverse proxy with a memorable hostname. Convenience features are how management planes end up in search engines.

**Three: ROMs are a legal surface, not just a technical one.** The container ships with no games, and that's the correct default. Homebrew and dumps of cartridges you own go in `data/<system>/roms/`; a folder of "totally legitimate" downloads is how a cute homelab project acquires an incriminating filesystem. The emulator is legal. Curate what you feed it.

## The receipts

Deployed on the reference tower: pinned `1.9.2`, management on `:3000`, player on `:3001`, both answering 200 from the LAN and refusing everything else, container on `restart: unless-stopped` so a power cut doesn't take the arcade down with it. Total server load while two browsers played: approximately nothing — the clients do the emulating, the antique does the filing.

A 14-year-old PC is a fine arcade cabinet. Just remember it's also a server, and servers don't get to be toys — they get to be *scoped*. Now if you'll excuse me, I have to go lose at a space shooter to a machine I personally firewalled.
