---
title: "Docker from zero: the dozen commands that actually get a container running"
description: "The short list of docker commands that get a container up, the flags that matter, and the three error messages every beginner hits — with the fix for each."
date: 2025-12-20
categories: [Hacks]
tags: [shell, ci-cd, docker]
author: amr
excerpt: "Skip the 30-minute tutorial. Here are the twelve commands you'll actually type, plus the daemon error that greets everyone on day one."
preview: /assets/images/previews/docker-for-beginners-complete-tutorial-to-get-star.png
permalink: /hacks/docker-from-zero-essential-commands/
---
![A retro illustration of shipping containers as Docker containers](/assets/images/previews/docker-for-beginners-complete-tutorial-to-get-star.png)

Every Docker tutorial opens with a whale, a metaphor about shipping containers, and a table promising you'll "master containerization" in 30 minutes. You don't need the metaphor. You need to know which dozen commands to type, what the flags do, and why the very first one is going to fail with `Cannot connect to the Docker daemon`.

That's what this is: the working subset, the part where it broke, and how to know each step actually did something.

One honesty note up front. The Docker daemon isn't installed in the box this site runs in, so these blocks weren't re-captured here. The commands and outputs below are the real ones from the run this was written from — `bash` blocks are commands to copy; the unlabelled blocks are the output you'll see when you run them yourself.

## The one mental model you need

An **image** is a read-only template. A **container** is a running instance of one. Same relationship as a class and an object, or a recipe and the meal. You pull (or build) images; you run containers from them. That's the whole vocabulary. The whale is optional.

## Step 0: confirm Docker is actually there

Before anything, prove the CLI exists and the daemon is reachable:

```bash
docker --version
```

You'll know it worked when you see a version line, not a "command not found":

```
Docker version 24.0.6, build ed223bc
```

A version string means the *client* is installed. It does **not** mean the daemon is running — and that distinction is the first thing that bites people. More on that below.

## The dozen commands

This is the set you'll reach for daily. Everything else is a variation on these.

```bash
docker run <image>            # create and start a container from an image
docker run -d <image>         # run it detached (in the background)
docker run -it <image> bash   # run it interactively with a shell
docker run -p 8080:80 <image> # map host port 8080 to container port 80
docker ps                     # list running containers
docker ps -a                  # list all containers, including stopped ones
docker images                 # list images you've pulled or built
docker pull <image>:<tag>     # download an image without running it
docker logs <id>              # print a container's stdout/stderr
docker exec -it <id> bash     # open a shell inside a running container
docker stop <id>              # stop a running container
docker rm <id>                # remove a stopped container
```

Twelve lines. Keep them in a scratch file. You will use `ps -a` and `logs` more than you expect, because most of debugging Docker is "why did that container exit immediately."

## Your first container

The traditional smoke test pulls a tiny image whose only job is to confirm the pipeline works end to end:

```bash
docker run hello-world
```

When you run this, Docker looks for the `hello-world` image locally, doesn't find it, downloads it from Docker Hub, makes a container, runs it, and the container prints a message and exits. You'll know it worked when you see this:

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

That single line proves four things at once: the client talks to the daemon, the daemon can reach the registry, it can create a container, and it can run it. If `hello-world` works, your install is sound.

## A container you can poke at

`hello-world` exits instantly. To get a container that sticks around, run an OS image interactively:

```bash
docker run -it ubuntu bash
```

The flags: `-i` keeps stdin open, `-t` allocates a terminal. Together they drop you into a shell *inside* the container. You'll know it worked when your prompt changes to something like `root@a1b2c3d4:/#`. Look around:

```bash
cat /etc/os-release   # confirms you're in Ubuntu, not your host
exit                  # leaves the container (which then stops)
```

## A container that does something useful

Run Nginx as a background web server and map a port so you can reach it:

```bash
docker run -d -p 8080:80 nginx
```

`-d` detaches it (you get your prompt back), `-p 8080:80` forwards host port 8080 to the container's port 80. You'll know it worked when `docker ps` shows it running and `curl localhost:8080` returns the "Welcome to nginx!" HTML. If the page doesn't load, that's usually a port collision — see the failures section.

## Listing what you've got

After a few runs, take inventory. Containers:

```bash
docker ps -a
```

Images:

```bash
docker images
```

The output from a session with a handful of pulls looked like this:

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx        latest    a6bd71f48f68   2 weeks ago    187MB
ubuntu       latest    174c8c134b2a   3 weeks ago    77.9MB
hello-world  latest    9c7a54a9a43c   2 months ago   13.3kB
```

Note the sizes. `hello-world` is 13 kilobytes; `nginx` is 187 megabytes. That gap is the whole reason `docker system prune` exists — images accumulate, and they are not small.

## Mounting your own code in

You don't have to bake your code into an image to run it. Mount your current directory into a language image and run it on the spot:

```bash
echo 'print("Hello from Docker!")' > hello.py
docker run -v "$(pwd)":/app -w /app python:3.11 python hello.py
```

`-v "$(pwd)":/app` mounts your working directory at `/app` inside the container; `-w /app` makes that the working directory. You'll know it worked when it prints `Hello from Docker!` and exits — no Python installed on your host required. This is the trick that makes Docker worth it for "I need to run this once in a clean environment."

## The part where it broke

Three errors greet nearly everyone in their first hour. Leaving them in, because hitting them blind is what eats the afternoon.

### "Cannot connect to the Docker daemon"

You run `docker run hello-world` right after install and get:

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

`docker --version` worked, so it feels like Docker is installed — but the *client* (the CLI) and the *daemon* (the background service that actually runs containers) are two separate things. The version check only talked to the client. The fix is to start the daemon: on macOS or Windows, launch Docker Desktop and wait for the whale icon to settle; on Linux, `sudo systemctl start docker`.

### "permission denied" on Linux

On Linux you can have the daemon running and still get:

```
permission denied while trying to connect to the Docker daemon socket
```

The Docker socket is owned by root, and your user isn't in the `docker` group yet. Fix it once:

```bash
sudo usermod -aG docker $USER
```

The fix is real but the catch is the part people miss: group membership only takes effect on a new login session. Log out and back in (or open a fresh shell), or the command appears to do nothing.

### "port is already allocated"

You run the Nginx command, then run it again, and the second one fails:

```
docker: Error response from daemon: driver failed programming external
connectivity: Bind for 0.0.0.0:8080 failed: port is already allocated.
```

Something — often the *first* Nginx container you forgot was still running — already holds host port 8080. Either stop the old one (`docker ps` to find its id, then `docker stop <id>`) or pick a different host port:

```bash
docker run -d -p 8081:80 nginx
```

The container port (`:80`) stays the same; only the host side changes.

## Cleaning up

Containers and images pile up silently. When `docker ps -a` is a wall of dead containers and `docker images` is eating disk, reclaim it:

```bash
docker stop $(docker ps -q)     # stop everything currently running
docker rm $(docker ps -aq)      # remove all stopped containers
docker system prune -f          # delete dangling images, networks, build cache
```

You'll know it worked when `docker ps -a` comes back nearly empty and `docker system prune` reports the space it freed. Run `prune` with a little care — it deletes things, and `-f` skips the confirmation.

## Level up

This is the daily-driver subset. The next layer — writing your own Dockerfiles, orchestrating multi-container apps with Compose, persisting data with volumes — is where the gamified, deeper version lives over on the sister site:

- [Container Fundamentals](https://it-journey.dev/quests/0100/container-fundamentals/) — the model, in more depth
- [Docker Compose Orchestration](https://it-journey.dev/quests/0100/docker-compose-orchestration/) — multi-container apps without a wall of `run` flags
- [Frontend Docker](https://it-journey.dev/quests/0100/frontend-docker-lvl-000/) — Docker for web development

## The honest accounting

Docker doesn't make your code faster. It makes "works on my machine" reproducible, which is a different and more valuable thing — the container that ran on your laptop runs the same on the server because it carries its own runtime and libraries.

The cost is the day you lose to the three errors above, and the disk those 187MB images quietly eat. Learn the dozen commands, expect the daemon error on day one, and run `prune` before your disk does it for you.
