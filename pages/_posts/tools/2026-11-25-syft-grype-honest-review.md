---
title: "Syft and Grype: the SBOM pair that lists everything in your image, then hands you 405 CVEs you mostly didn't write"
description: "A stress-tested review of Syft and Grype: what the SBOM misses, why the same image scores 405 or 291, and how it stacks up against Trivy."
date: 2026-11-25
preview: /images/previews/syft-and-grype-the-sbom-pair-that-lists-everything.svg
categories: [Tools]
tags: [system, data]
author: edge
verdict: "Use it — survives a bad Tuesday. The inventory is good and the gate works. But the number it gives you depends on the SBOM format, the database date, and whether your binaries kept their names, so write all three down next to it."
excerpt: "I built a 235 MB Python image with two pinned dependencies and got 405 vulnerability matches. I wrote 15 of them. Then I renamed one binary and it vanished from the inventory, and a scratch image holding ripgrep came back 'No vulnerabilities found'."
permalink: /tools/syft-grype-honest-review/
---
I review tools by finding the number people paste into a ticket and checking where it came from. Syft and Grype are Anchore's two free, single-binary CLIs for the question "what is actually in prod, and is any of it on fire?" Syft writes down what's inside a container image, which is the SBOM (software bill of materials). Grype reads that list and matches it against vulnerability databases. They split the job, so you can store the inventory today and re-check it tomorrow without pulling the image again. It's a good design. It also means the number at the bottom of the report goes through two tools, one file format, and one database snapshot before it reaches you, and every hop changes it.

The idea came from it-journey's [Artifact Management quest](https://it-journey.dev/quests/0101/artifact-management/), which treats an SBOM as part of a properly versioned, signed build artifact. I agree. I wanted to see how far you can trust one.

**The verdict, up front:** use it. Syft found every package that a package manager recorded, plus a `curl`ed binary I didn't expect it to catch. Grype's `--fail-on` gate exits non-zero exactly when it should. It survives a normal Tuesday and a bad Tuesday. It does not survive the Tuesday where the intern has sudo, because the intern will rename a binary, generate the SBOM in the format the README shows, scan it with a different tool's scanner, and paste whatever number comes out into the audit spreadsheet. Below are the ways that number moves without the image changing at all.

Disclosure: I have no relationship with Anchore or with Aqua Security (who make Trivy, the comparison at the end). All three tools are Apache-2.0. Nobody paid me, and the only thing I got out of this is a table.

## The rig

Everything below ran on 2026-11-25, on an Ubuntu 26.04 x86_64 runner with Docker 29.4.2, using each project's own install script:

```console
$ syft version | sed -n 2p; grype version | sed -n 2p; trivy --version
Version:       1.57.2
Version:             0.122.1
Version: 0.76.2
```

The test subject is `myapp:1.4.2`, a 235 MB image built on `python:3.11-slim` (Debian 13.8, built 2026-11-24, the day before I tested). I put traps in it on purpose:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# the curl'd binary nobody's package manager recorded
ADD https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 /usr/local/bin/jq
RUN chmod +x /usr/local/bin/jq && cp /usr/local/bin/jq /usr/local/bin/totally-not-jq
ADD https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz /tmp/rg.tgz
RUN tar -xzf /tmp/rg.tgz -C /tmp && mv /tmp/ripgrep-13.0.0-x86_64-unknown-linux-musl/rg /usr/local/bin/rg && rm -rf /tmp/rg* /tmp/ripgrep*
ADD https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64 /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq
# installed, then "removed" in a later layer
RUN pip install --no-cache-dir urllib3==1.24.1 --target /opt/old && true
RUN rm -rf /opt/old
COPY app.py .
CMD ["python","app.py"]
```

`requirements.txt` pins two packages, `requests==2.25.1` and `flask==2.0.1`. On top of that there are three binaries I downloaded with no package manager involved (plus one renamed copy), and one package I installed and then deleted. That last one is a common Dockerfile mistake.

## Step one: the inventory

```console
$ time syft myapp:1.4.2 -o spdx-json > sbom.spdx.json
real	0m3.187s
$ ls -la sbom.spdx.json
-rw-r--r-- 1 runner runner 2546119 Nov 25 23:02 sbom.spdx.json
```

It took three seconds and wrote 2.5 MB of SPDX JSON. Syft's own JSON output listed 155 packages: 87 Debian packages, 31 Python packages, 21 Go modules, and 16 binaries it identified by fingerprint. Then I asked which of my `curl`ed files made it in. I filtered Syft's JSON on each file's path:

| File in `/usr/local/bin` | How it got there | Packages Syft recorded | |
| --- | --- | --- | --- |
| `yq` | Go binary, downloaded | 21 (yq plus the Go stdlib and 19 modules, read from Go's embedded build info) | ✅ |
| `jq` | C binary, downloaded | 1 (`jq 1.6`, type `binary`) | ✅ |
| `totally-not-jq` | byte-for-byte copy of `jq` | 0 | ❌ |
| `rg` | Rust binary, downloaded | 0 | ❌ |

The jq result surprised me in a good way. Syft has a set of binary classifiers that recognise well-known programs by the version strings inside them, and jq 1.6 is one of them. The renamed copy is the catch. The bytes are identical and the result is zero, because the classifier only looks at files whose *name* matches what it expects. **The failure this prevents:** a vendored tool someone renamed to avoid a `$PATH` clash (`jq16`, `node-old`, `python-legacy`) is not in your inventory, so it's not in your vulnerability report either. Ripgrep is invisible for a different reason. A Rust binary only carries its dependency list if it was built with `cargo auditable`, and ripgrep 13's release binary wasn't. Go puts build info in every binary by default, which is why yq turned into 21 rows and ripgrep turned into nothing.

The deleted package is next. By default Syft scans the *squashed* image, meaning the filesystem you'd see in a running container, so `urllib3 1.24.1` doesn't appear. The bytes are still in the layer, though, and anyone who pulls the image gets them. `--scope all-layers` finds them:

```console
$ syft myapp:1.4.2 -q --scope all-layers -o json | jq -r '.artifacts[]|select(.name=="urllib3")|[.name,.version,.locations[0].path]|@tsv'
urllib3	1.24.1	/opt/old/urllib3-1.24.1.dist-info/METADATA
urllib3	1.26.20	/usr/local/lib/python3.11/site-packages/urllib3-1.26.20.dist-info/METADATA
```

Run through Grype with the same scope, the deleted package adds 13 matches (291 → 304). Whether those 13 count is a policy question, and the default answer is "no". That's defensible, because the files can't run, but it's worth knowing that the default made that call for you.

## Step two: the scan, and who wrote the bugs

```console
$ time grype sbom:sbom.spdx.json -o json > g.json
 WARN go binary packages were found but none carry function symbols; go vulnerability matching falls back to module granularity and may report false positives. if scanning an SBOM, regenerate it with symbol capture enabled for more precise results.
real	1m8.267s
```

The first run took a minute because it downloaded the vulnerability database (built `2026-11-25T06:22:21Z`). It returned **405 matches** across 275 unique vulnerability IDs: 8 Critical, 160 High, 162 Medium, 18 Low, 51 Negligible, 6 Unknown. Ignore the warning for now. It comes back.

Then I sorted each match by who put that package in the image. I did the split with a small `jq` script that groups by package name and type. I also checked it against a separate scan of `python:3.11-slim` on its own, which came back with 236 matches, exactly the base rows below.

| Who put it there | Matches | `--only-fixed` |
| --- | ---: | ---: |
| Base image: Debian packages | 212 | 1 |
| Base image: Python and its bundled pip/setuptools/wheel | 24 | 24 |
| Me: `requirements.txt` (flask, requests, and their urllib3, idna) | 15 | 15 |
| Me, via `curl`: jq 1.6 | 20 | 7 |
| Me, via `curl`: yq (Go modules) | 134 | 134 |
| **Total** | **405** | **181** |

My `requirements.txt` accounts for 15 of 405, about 4%. The base image accounts for 236, or 58%, and that's an official image built *the day before*. **The failure this prevents:** a team gets told "your service has 405 vulnerabilities," spends a sprint upgrading Flask, rescans, and gets 403.

`--only-fixed` is the usual first cut, and it's a big one. It keeps only matches where a fixed version exists. It took Debian from 212 to 1, because Debian marks most of those `not-fixed` (90) or `wont-fix` (121). The one fixable Debian match is `libzstd1`, CVE-2026-124851, whose fix is dated 2026-11-24. That's the day the base image was built, so the fix just missed it.

"Has a fix" is not the same as "easy to fix", though. Eight of my 15 are urllib3 1.26.20, and every fix Grype lists for them is a 2.x release. requests 2.25.1 won't allow that:

```console
$ docker run --rm myapp:1.4.2 sh -c "grep -i '^Requires-Dist: urllib3' /usr/local/lib/python3.11/site-packages/requests-2.25.1.dist-info/METADATA"
Requires-Dist: urllib3 (<1.27,>=1.21.1)
```

So fixing urllib3 means upgrading requests first. The report lists them as separate findings.

## Step three: the CI gate

```console
$ grype sbom:sbom.spdx.json -q --fail-on high -o table > /dev/null; echo "exit=$?"
exit=2
```

It exits 2, which fails the CI step, and that's correct. Then the test nobody runs: I gated the *untouched base image* with the friendliest settings available.

```console
$ grype python:3.11-slim -q --only-fixed --fail-on high -o json > bf.json; echo "exit=$?"
exit=2
```

That also exits 2. The official image, built yesterday, with only fixable findings counted, fails a `high` gate before I've added a single line: `wheel 0.45.1` (GHSA-8rrh-rw8j-w5fx) and `jaraco-context 5.3.0` (GHSA-58pv-8j8x-9vj2, which setuptools bundles) are both High. **The failure this prevents:** you add the gate on Friday, every pipeline on the team goes red on Monday, and somebody adds `|| true` to make it stop. Plan for a baseline: decide what you accept from the base image, put it in Grype's `ignore` config with a reason, and gate on what's new.

## Surprise one: same image, same database, 405 or 291

For a sanity check, I pointed Grype straight at the image instead of the SBOM:

```console
$ grype myapp:1.4.2 -q -o json | jq '.matches|length'
291
```

That's 291 instead of 405, from the same image and the same database. The whole difference is in the Go modules: 134 matches via the SBOM against 20 when scanning the image directly. When Grype scans an image it can read which functions the Go binary actually contains, and skip vulnerabilities in code that isn't there. An SBOM normally doesn't carry that information. That's what the warning was about, and it tells you how to fix it: "regenerate it with symbol capture enabled." So I did:

```console
$ SYFT_GOLANG_CAPTURE_SYMBOLS=extended-stdlib syft myapp:1.4.2 -q -o spdx-json > sbom-sym.spdx.json
$ SYFT_GOLANG_CAPTURE_SYMBOLS=extended-stdlib syft myapp:1.4.2 -q -o syft-json > sbom-sym.syft.json
$ SYFT_GOLANG_CAPTURE_SYMBOLS=extended-stdlib syft myapp:1.4.2 -q -o cyclonedx-json > sbom-sym.cdx.json
```

| SBOM fed to Grype | Matches | Go matches | Warning? |
| --- | ---: | ---: | --- |
| SPDX JSON, default | 405 | 134 | yes |
| SPDX JSON, symbols captured | 405 | 134 | yes, same advice |
| CycloneDX JSON, symbols captured | 405 | 134 | yes, same advice |
| Syft JSON, symbols captured | 291 | 20 | no |
| (the image itself, no SBOM) | 291 | 20 | no |

The symbols only survive in Syft's own JSON format. In the two standard formats, the ones you'd hand to an auditor or another tool, Syft captures them and the file doesn't keep them. Grype then gives the same advice again for a file you already regenerated. With Syft JSON plus `--only-fixed`, the list drops from 181 to **67**. **The failure this prevents:** 114 Go findings that Grype itself says "may" be false positives, and a week spent triaging them. If you're storing SBOMs to rescan later, store Syft JSON with symbols *as well as* your SPDX or CycloneDX copy.

## Surprise two: the SBOM is a different file every time

An SBOM is supposed to be the stable record of a build, so I generated ten from the same image and hashed them:

```console
$ for i in $(seq 1 10); do syft myapp:1.4.2 -q -o spdx-json | sha256sum | cut -c1-12; done | sort -u | wc -l
10
```

I got ten different files. Some of that is by design: SPDX requires a creation timestamp and a unique document namespace, so I removed `created` and `documentNamespace` and sorted every array to rule out ordering. After that, ten runs still came out as two distinct documents. In 20 more runs I tracked one edge in the dependency graph, which version of `packaging` that setuptools depends on:

```console
      8 24.2
     12 26.4
```

The image has two copies of `packaging`, 24.2 and 26.4, and four `DEPENDENCY_OF` edges (out of 3,783 relationships) get assigned to one or the other depending on the run. The package list was identical every time, so this doesn't change any vulnerability count. **The failure this prevents:** you sign SBOMs and compare them in CI to detect "the build changed", and it reports a change on a build that didn't change. On this image the edge flipped often enough (8 of 20 runs one way, 12 the other) that a hash comparison is mostly noise. Compare the sorted package list, not the file hash.

## Surprise three: the clean scan

The obvious question is whether a clean scan of the app layer says anything about the rest. I tried something more extreme: an image that is nothing *but* a binary.

```console
$ printf 'FROM scratch\nCOPY rg /rg\nENTRYPOINT ["/rg"]\n' > Dockerfile && docker build -q -t rgonly:1 .
$ docker run --rm rgonly:1 --version | head -1
ripgrep 13.0.0 (rev af6b6c543b)
$ syft rgonly:1 -q -o table; echo "exit=$?"
No packages discovered
exit=0
$ grype rgonly:1 --fail-on low -o table 2>&1 | tail -1; echo "exit=${PIPESTATUS[0]}"
No vulnerabilities found
exit=0
```

"No vulnerabilities found" is true and also useless. Grype found no vulnerabilities in zero packages, and passed a gate set to fail on *low*. **The failure this prevents:** shipping distroless or `scratch` images full of downloaded binaries, and putting "0 CVEs" on the slide. Add a check that fails when the package count is suspiciously low for what you know is in there, for example `syft -o json | jq '.artifacts|length'` compared against a floor.

## The time problem

The vulnerability database updates constantly, so a scan is a dated claim. I wanted to prove it by rescanning against last week's database, and I couldn't: Anchore's v6 listing (`grype.anchore.io/databases/v6/latest.json`) only serves the current one. What I can show is how recent the current result is. Grype includes the release date of each fix, and 11 of the 405 matches have a first fix released in the last 30 days. Each of those changed status within the month, including the one that moved `libzstd1` into the `--only-fixed` list. **The failure this prevents:** an SBOM scanned in January and filed as "clean" in a compliance folder. Write the DB build date next to every number: `grype db status` prints it.

## The free alternative: Trivy on the same image

Trivy does both jobs in one binary, so I ran it on the same image:

```console
$ trivy image -q --format json -o t.json myapp:1.4.2
$ jq -r '.Results[]|"\(.Class)\t\(.Type)\t\(.Target)\t\(.Vulnerabilities|length)"' t.json
os-pkgs	debian	myapp:1.4.2 (debian 13.8)	225
lang-pkgs	python-pkg	Python	25
lang-pkgs	gobinary	usr/local/bin/yq	133
```

| | Grype (image) | Trivy (image) |
| --- | ---: | ---: |
| Debian | 212 | 225 |
| Python packages | 25 | 25 |
| Python interpreter binary | 14 | not detected |
| jq 1.6 | 20 | not detected |
| yq (Go) | 20 | 133 |
| ripgrep, renamed jq | not detected | not detected |
| **Total** | **291** | **383** |

Trivy sees the same packages a package manager recorded, plus yq, which it scores at module level like the Grype SBOM path. It doesn't see the downloaded jq at all. Neither tool sees ripgrep or the renamed copy. Neither one is "right"; they each count differently.

Then I tried the obvious cross-check, Trivy's SBOM scanned by Grype. SPDX is a standard, after all:

```console
$ trivy image -q --format spdx-json -o t.spdx.json myapp:1.4.2
$ grype sbom:t.spdx.json -q -o json | jq '.matches|length'
192
```

**192.** Debian drops from 212 to 33, with no warning. Here's the reason:

```console
pkg:deb/debian/libc6@2.41-12%2Bdeb13u5?arch=amd64&distro=debian-13.8&upstream=glibc   # Syft
pkg:deb/debian/libc6@2.41-12%2Bdeb13u5?arch=amd64&distro=debian-13.8                  # Trivy
```

Debian tracks vulnerabilities by *source* package (glibc), not binary package (libc6). Syft's package URL includes `upstream=glibc`. Trivy's doesn't, so Grype can't connect libc6 to glibc's advisories. Packages whose binary and source names match (`coreutils`, `dpkg`, `tar`, `openssl`) still match. Everything else gives zero. The tools share a standard format, but that doesn't mean they're interchangeable. **The failure this prevents:** a supplier hands you their SBOM, you scan it with your scanner, you get 192, and you believe it. When a number matters, scan with the same tool family that wrote the SBOM, or scan the image.

## The results table

| Scenario | Result | |
| --- | --- | --- |
| SBOM of a 235 MB image | 3.2 s, 155 packages | ✅ |
| `curl`ed jq 1.6 | found by binary classifier | ✅ |
| `curl`ed yq (Go) | found, with 20 modules and stdlib | ✅ |
| `curl`ed ripgrep (Rust) | not in SBOM | ❌ |
| byte-identical jq, renamed | not in SBOM | ❌ |
| package deleted in a later layer | hidden by default; `--scope all-layers` finds it (+13) | ✅ if you ask |
| `--fail-on high` on my image | exit 2 | ✅ |
| `--only-fixed --fail-on high` on the untouched official base | exit 2 | ⚠️ plan a baseline |
| same image via SPDX vs direct | 405 vs 291 | ❌ format changes the count |
| warning's advice, followed, in SPDX/CycloneDX | still 405, same warning | ❌ |
| Syft JSON with Go symbols | 291; `--only-fixed` 67 | ✅ |
| 10 SBOMs of one image | 10 hashes; 2 after normalising | ❌ don't diff by hash |
| `scratch` image holding ripgrep | "No vulnerabilities found", exit 0 on `--fail-on low` | ❌ silence ≠ safe |
| Trivy's SPDX scanned by Grype | 192 (Debian 212 → 33), no warning | ❌ |

## Verdict

**Use it. It survives a bad Tuesday.** Syft is fast and catches more than I expected, including a downloaded jq. Grype's gate is reliable, and splitting the two tools means you keep the inventory and rescan it whenever the database moves. That's exactly what the Artifact Management quest is asking you to do.

What it won't do is give you a number that means anything without context. Every count above came from the same 235 MB image. Treat any vulnerability count as a measurement and record the conditions with it: the SBOM format (Syft JSON with `SYFT_GOLANG_CAPTURE_SYMBOLS` if you want the smaller, more accurate Go count), the DB build date from `grype db status`, the scope, and the fact that renamed or Rust binaries aren't in the inventory at all. Gate on what's new compared with an agreed base-image baseline, not on the raw total. If you want one tool instead of two, Trivy is the free alternative and does fine on the same image. Just don't mix one tool's SBOM with the other's scanner and trust the result.

I tried to break the inventory and mostly couldn't, which is annoying. The numbers built on top of it, though, moved every time I changed something.
