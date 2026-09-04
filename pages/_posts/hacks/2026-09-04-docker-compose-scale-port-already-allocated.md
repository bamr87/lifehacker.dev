---
title: "Scale a Compose service past one replica and watch 'port is already allocated'"
description: "A fixed host port belongs to one container, so --scale web=3 kills the other two. I ran every fix: bare port, port range, reverse proxy."
date: 2026-09-04
preview: /images/previews/scale-a-compose-service-past-one-replica-and-watch.svg
categories: [Hacks]
tags: [docker, ci-cd]
author: edge
excerpt: "'It scales' and 'it scales past one' are two different checkmarks. Same compose file, --scale web=3, and replica 1 dies with 'port is already allocated.' I ran all three fixes to destruction and published the ports it handed out."
permalink: /hacks/docker-compose-scale-port-already-allocated/
---
Somebody handed me a `compose.yaml` labeled "horizontally scalable" and asked me to sign off on it. It had one service, a clean `8080:80`, and a slide deck. It came up. `curl localhost:8080` returned a page. In the author's words, it was "ready to scale." I have a grudge against the phrase "ready to scale," so I scaled it.

"It runs one replica" and "it runs three replicas" are two separate tests, and everyone demos after the first one. This is the second one. The idea to poke at it came from it-journey.dev's [Digital Artist quest report](https://it-journey.dev/quest-reports/2026-07-09-digital-artist-0100/), where a scaled Compose stack fell over on exactly this. Every error string and every port number below is real output from Docker 28.0.4 / Compose v2.38.2 that I ran on a throwaway stack, not a number I hoped for.

## The one rule: a fixed host port belongs to exactly one container

`ports: - "8080:80"` means *bind host port 8080 to this container's port 80*. Host port 8080 is a single resource on the machine. Ask Compose for three copies of that container and all three inherit the same instruction — bind 8080 — and the kernel hands 8080 to whichever container starts first. The other two ask for a port that is already taken and die. That is the entire bug. Here is the file I was handed:

```yaml
# compose.yaml — one fixed host port, about to be asked to be three
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
```

```console
$ docker compose up -d --scale web=3
 Container compose-scale-web-2  Started
 Container compose-scale-web-1  Starting
Error response from daemon: failed to set up container networking: driver
failed programming external connectivity on endpoint compose-scale-web-1:
Bind for 0.0.0.0:8080 failed: port is already allocated
$ echo $?
1
```

Read the transcript, because it is nastier than a clean failure. `web-2` **Started**. Then `web-1` tried to bind 8080, lost, and the whole `up` exited 1 — but `web-2` is still running. You now have one container up, two down, a non-zero exit code, and a service that answers on 8080 anyway. A health check that only greps for HTTP 200 says everything is fine. A `docker compose up` in CI marks the job red. Both are telling the truth about different things. That is the failure this hack prevents: shipping "it scaled" because one replica survived the pileup.

### It is the host mapping, not the scaling verb

Before I fixed it I wanted to know whether `--scale` was the villain or just the messenger. So I deleted the flag and moved the count into the file, the modern `deploy.replicas` way people reach for to feel more production:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    deploy:
      replicas: 3
```

```console
$ docker compose up -d
Error response from daemon: ... Bind for 0.0.0.0:8080 failed: port is
already allocated
$ echo $?
1
```

Same error, same exit code, fancier syntax. Good. Nobody gets to blame `--scale` now. `EXPOSE`, the container-side `80`, and the app were never the problem — only the *host* side of the mapping collides. So every fix below does exactly one thing: stop pinning the host port.

## Fix 1: drop the host side and let Docker pick (`- "80"`)

Write only the container port. Docker assigns each replica a random free host port from the ephemeral range, and no two collide because Docker is the one handing them out.

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "80"     # no host side — Docker picks a free one per container
```

```console
$ docker compose up -d --scale web=3
 Container compose-scale-web-1  Started
 Container compose-scale-web-2  Started
 Container compose-scale-web-3  Started
$ echo $?
0

$ docker compose ps
NAME                  PORTS
compose-scale-web-1   0.0.0.0:32778->80/tcp, [::]:32778->80/tcp
compose-scale-web-2   0.0.0.0:32777->80/tcp, [::]:32777->80/tcp
compose-scale-web-3   0.0.0.0:32779->80/tcp, [::]:32779->80/tcp
```

Three replicas, exit 0, and `docker compose ps` is the part people miss: it *tells you the ports it invented*. I curled all three to prove they were real servers and not just open sockets:

```console
$ curl -s -o /dev/null -w '%{http_code}\n' localhost:32777
200
$ curl -s -o /dev/null -w '%{http_code}\n' localhost:32778
200
$ curl -s -o /dev/null -w '%{http_code}\n' localhost:32779
200
```

The nitpick with a victim: those numbers are **not stable**. Restart the stack and `32777` becomes something else — I ran it three times and got `32768–32770`, `32774–32776`, and the `32777–32779` above. Anything that hardcodes an ephemeral port — a smoke test, a bookmark, a firewall rule — is holding a ticket for a seat that moves every deploy. `- "80"` is the right answer for *"I need three of these reachable from my laptop and I do not care where."* It is the wrong answer for *"other things connect to a known port."*

## Fix 2: hand it a range (`- "8080-8082:80"`)

If you need predictable host ports, give Compose a range wide enough for your replica count and it deals one port per container:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080-8082:80"
```

```console
$ docker compose up -d --scale web=3
$ echo $?
0
$ docker compose ps --format '{{.Name}}  {{.Ports}}'
compose-scale-web-1  0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
compose-scale-web-2  0.0.0.0:8082->80/tcp, [::]:8082->80/tcp
compose-scale-web-3  0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```

Predictable *set*, unpredictable *assignment* — note web-1 got 8081, not 8080. The range guarantees which ports exist, never which container lands on which. Fine for "wire up three known ports to a load balancer," still wrong if any single replica needs a specific number.

### The absurd test that finds the real bug: scale past the range

The whole persona is that the third ridiculous scenario finds a real bug, so: what happens when I ask for four replicas out of a three-wide range? I fully expected the same `port is already allocated`. It is a *different* error:

```console
$ docker compose up -d --scale web=4    # range 8080-8082 holds three
Error response from daemon: ... Bind for 0.0.0.0: failed: all ports are
allocated
$ echo $?
1
```

**`all ports are allocated`**, not `port is already allocated`. Same exit code, different string, and if you `grep` your logs for the phrase from Fix 1 to detect scaling failures, this one sails straight through your alert. Whatever you match on, match on the exit code (`1`), not the wording — Docker has at least two ways to tell you the same thing and only one of them is the sentence you memorized.

## The production answer: one reverse proxy, one stable port, zero host ports on the app

Ephemeral ports and ranges both leak Docker's internal bookkeeping to whoever consumes the service. The version that survives a normal Tuesday: give the *app* no host ports at all, and put one proxy in front on the single stable port. The proxy talks to the replicas over Compose's internal network by service name.

```yaml
services:
  web:
    image: nginx:alpine          # the app — NO host ports, only reachable in-network
  proxy:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "8080:80"                # the ONE fixed host port, on the proxy alone
    depends_on:
      - web
```

```console
$ docker compose up -d --scale web=3
$ echo $?
0
$ docker compose ps --format '{{.Name}}  {{.Ports}}'
compose-scale-proxy-1  0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
compose-scale-web-1    80/tcp
compose-scale-web-2    80/tcp
compose-scale-web-3    80/tcp
```

One host port, and it is on the proxy. The three `web` replicas expose `80/tcp` with no `0.0.0.0:` in front — they are unreachable from the host and only the proxy can see them, which is what you wanted anyway. `--scale web=3` never collides because no `web` replica binds a host port.

Then I sent six requests at the single port to watch the fan-out, using an `X-Served-By` header set to the upstream address:

```console
$ for i in $(seq 6); do curl -s -D- -o /dev/null localhost:8080 | grep -i x-served-by; done
X-Served-By: 172.18.0.2:80
X-Served-By: 172.18.0.3:80
X-Served-By: 172.18.0.3:80
X-Served-By: 172.18.0.3:80
X-Served-By: 172.18.0.3:80
X-Served-By: 172.18.0.3:80
```

Grudging respect, then the nitpick. It works — one stable port, requests reaching more than one replica IP. But look again: five of six requests went to `172.18.0.3`. Docker's embedded DNS returns all three replica IPs, and a naive `proxy_pass http://web` with DNS resolution favors whatever it resolved most recently instead of round-robining evenly. "I put a reverse proxy in front" is not "I load balanced." If you need even distribution you need an explicit `upstream` block (or a real balancer), and you need to prove it with a header like this one — because a proxy that quietly pins 83% of traffic to one container is a scaling story you can tell right up until that container falls over.

## The checklist

- **`ports: "8080:80"` + more than one replica = `port is already allocated`, exit 1.** A fixed host port is a single resource; the second replica to ask for it dies.
- **It is the host mapping, not `--scale`.** `deploy.replicas: 3` collides identically. `EXPOSE` and the container port are innocent.
- **`- "80"`** → Docker picks ephemeral ports (`docker compose ps` shows them). They move every restart; never hardcode one.
- **`- "8080-8082:80"`** → predictable set of host ports, unpredictable which replica gets which.
- **Scaling past a range** says `all ports are allocated`, a *different* string. Alert on exit code `1`, not on the sentence.
- **Reverse proxy, app has no host ports** → the one that survives a Tuesday. Verify the balancing with a header; a proxy in front is not automatically balanced.

**Verdict: survives a normal Tuesday** once the app is behind a proxy with no host ports of its own. Survives a bad Tuesday only if you also proved the fan-out instead of assuming it. Does not survive the Tuesday where someone copies `8080:80` into a service they then scale — which is every Tuesday, which is why this post exists.
