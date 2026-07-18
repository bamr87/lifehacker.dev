---
title: "WSL2: a real Linux dev box on Windows in about ten minutes"
description: "Install WSL2, get an Ubuntu shell with full apt, and the daemon-style errors that greet you first: virtualization off in BIOS and a distro stuck on WSL1."
date: 2026-06-26
categories: [Hacks]
tags: [shell]
author: amr
excerpt: "One command installs a real Linux kernel on Windows. Here's the command, the in-distro check, and the two failures that eat your first morning."
preview: /images/previews/section-hacks.svg
permalink: /hacks/windows-sub-linux-setup/
---
Every "set up your dev environment on Windows" guide eventually tells you to install a virtual machine, allocate it 8GB of RAM you don't have, and reboot into a second computer that boots slower than the first one.

You don't need a VM. Windows ships a real Linux kernel now. One command installs it, and you get an actual `apt`-having Ubuntu shell that shares your filesystem and your clipboard, running next to Windows instead of on top of it.

This is the command, the check that proves it's really Linux and not a costume, and the two errors that greet most people before any of it works.

One honesty note up front: this site's build box runs macOS, not Windows, so the `wsl` and PowerShell blocks below were **not** re-captured here — they're the standard Microsoft commands, shown as documentation. The one block that prints real output is the in-distro version check near the end, which runs the same in WSL as in any Linux shell, and which we did run.

## What you need first

- Windows 10 version 2004+ (build 19041+) or Windows 11.
- An **administrator** PowerShell or Terminal. The install touches Windows features; a normal prompt will refuse.

## The one command

Open PowerShell **as Administrator** and run:

```powershell
wsl --install
```

That single command does four things people used to do by hand: it enables the WSL and Virtual Machine Platform Windows features, downloads the Linux kernel, sets WSL2 as the default, and installs Ubuntu as the default distribution.

You'll know it worked when it tells you it's installing Ubuntu and asks you to **reboot**. Reboot. This part is not optional — the Windows features it just enabled don't take effect until you do, and skipping it is the most common reason the next step fails.

After the reboot, an Ubuntu window opens on its own and asks you to create a UNIX username and password. This account is separate from your Windows login. Pick something you'll remember; you'll type the password every time you `sudo`.

## First thing inside the shell

You're now at a real bash prompt. Update the package lists and upgrade what shipped in the image:

```bash
sudo apt update && sudo apt upgrade -y
```

You'll know it worked when `apt update` lists a few Ubuntu mirrors with `Hit`/`Get` lines and ends with a package count, and the upgrade runs to completion without a network error. If it hangs at 0% forever, that's almost always a DNS problem inside the distro — covered in the failures section.

## Prove it's actually Linux

Here's the check that confirms you got the real thing and not a compatibility shim. Every Linux distribution publishes its identity in `/etc/os-release`; this pipeline pulls the one line that matters:

```bash
# lh:run
cat > os-release <<'EOF'
PRETTY_NAME="Ubuntu 22.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
ID=ubuntu
EOF
grep '^PRETTY_NAME=' os-release | cut -d'"' -f2
```

That prints:

```
Ubuntu 22.04.3 LTS
```

Inside a real WSL2 Ubuntu shell you'd run `grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2` directly (no `cat` setup — the file is already there) and see the same shape. We faked the file here only because this build box is macOS and has no `/etc/os-release`; the `grep | cut` pipeline is the real, runnable part, and it's exactly what you'll type in the distro.

Then confirm Windows itself sees the distro as **WSL2**, not WSL1 — the version number is the whole point:

```powershell
wsl --list --verbose
```

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

That `2` in the VERSION column is the line to check. WSL1 translates Linux syscalls; WSL2 runs a genuine kernel in a lightweight VM, which is what makes Docker, `inotify` file-watchers, and most of the ecosystem actually work. If you see a `1` there, see the second failure below.

## The tools you'll want immediately

The base image is intentionally bare. Install the developer essentials in one shot:

```bash
sudo apt install -y git curl build-essential
```

You'll know it worked when `git --version`, `curl --version`, and `gcc --version` each print a version line instead of a "command not found". `build-essential` is the bundle that pulls in `gcc`, `make`, and the headers that half of `npm install` and `pip install` secretly compile against — install it now and save yourself a wall of confusing build errors later.

From here your `\\wsl$\Ubuntu` filesystem is reachable from Windows Explorer, and editors like VS Code will offer to reopen the folder "in WSL" so the terminal, extensions, and language servers all run Linux-side.

## The part where it broke

Two failures catch nearly everyone before any of the above works. Leaving them in, because hitting them cold is what turns ten minutes into a morning.

### "WSL2 requires an update to its kernel component" / it hangs on first launch

You run `wsl --install`, reboot, and Ubuntu either errors out or sits forever. The usual cause isn't WSL at all — it's that **hardware virtualization is disabled in BIOS/UEFI**. WSL2's lightweight VM can't start without it.

Check from an admin PowerShell first:

```powershell
systeminfo | Select-String "Virtualization"
```

If it reports `Virtualization Enabled In Firmware: No`, the fix lives in firmware, not Windows: reboot into BIOS/UEFI (usually `Del` or `F2` at power-on), find the setting named **Intel VT-x**, **AMD-V**, or plain **Virtualization**, enable it, save, and boot back. There is no software workaround — the CPU feature has to be on.

If the kernel component itself is what's out of date, that error message links to the fix, and so does:

```powershell
wsl --update
```

### Your distro is stuck on WSL1

`wsl --list --verbose` shows a `1` in the VERSION column. This happens on machines that had an older WSL before, where WSL1 was the default. The distro works, but you're on the syscall-translation layer, and you'll hit walls the moment you try to run Docker or anything that watches files.

Convert it in place — your files come along:

```powershell
wsl --set-version Ubuntu 2
```

You'll know it worked when it prints `Conversion complete` (give it a minute on a large distro) and `wsl --list --verbose` now shows `2`. While you're there, set the default so new distros land on WSL2 automatically:

```powershell
wsl --set-default-version 2
```

## The honest accounting

WSL2 doesn't make Windows into Linux. The integration is good but not invisible — accessing Windows files (`/mnt/c/...`) from inside the distro is noticeably slower than native Linux files, so keep your projects on the Linux side (`~/`), not on `/mnt/c`, or your `git status` will crawl in a large repo.

What you get for the ten minutes is real: an actual Linux kernel, real `apt`, real Docker support, and one filesystem and clipboard shared with Windows instead of a second machine to alt-tab into. Install it, enable virtualization before you curse at it, and check for that `2` in the VERSION column before you trust anything else.
