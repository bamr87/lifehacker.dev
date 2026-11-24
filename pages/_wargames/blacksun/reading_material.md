---
title: "Blacksun reading material"
description: "Blacksun reading list — papers on format strings, heap exploitation, frame-pointer overwrites, ASLR, PaX, stack protection and hardware defences."
excerpt: "Blacksun reading list — papers on format strings, heap exploitation, frame-pointer overwrites, ASLR, PaX, stack protection and hardware defences."
permalink: /wargames/blacksun/reading_material/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- blacksun
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/blacksun/reading_material.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- reading
- material
author: amr
nav_order: -1
sidebar_label: "Reading material"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Reading material
================

Below is a list of overall reading material which you may wish to read over before starting.

Bug class exploitation
----------------------

### Format strings:

-   [Scut's formatstring paper][] (class paper and recommended reading)
-   [Advances in format string exploitation][]
-   [Format bug analysis][]
-   [Vulnerabilities in your code - Format Strings][]
-   [The Mystery of Format String Exploitation][]

### Heap exploitation

-   [Once upon a free()][] - Historical document, later glibc's have additional checking
-   [Vudo - An object superstitiously believed to embody magical powers][] - ""
-   [Advanced Doug lea's malloc exploits][] - ""
-   [Malloc Maleficarum][] - Recent glibc malloc exploitation document, should be relevant for blacksun

### Frame pointer overwrites

-   [Framepointer overwrites][]

### Adress space layout randomisation (ASLR)/ PaX specific

-   [Bypassing PaX ASLR protection][] - somewhat outdated.
-   [The advanced return-into-lib(c) exploits: PaX case study][] - ""
-   [PaX documentation][] - external link
-   [Smash the stack - Advanced bufferoverflow methods][]

### Execshield documents

-   [A Solution To Red Hat PIE Protection][] - External link
-   [How to Exploit Overflow Vulnerability Under Fedora Core][] - External link

### Stackguard / Stack smashing protection

-   [Stack Smashing Protection homepage][] - external link
-   [Bypassing StackGuard and StackShield][]
-   [Four different tricks to bypass StackShield and StackGuard protection][]
-   [Defeating compiler-level buffer overflow protection][]

### Hardware protection (e.g amd64 / nx bit)

-   [x86-64 buffer overflow exploits and the borrowed chunks exploitation technique][]

Generalised papers / notes / presentations (not always indepth)
---------------------------------------------------------------

-   [A Comparison of Buffer Overflow Prevention Implementations and Their Weaknesses][]
-   [Spender's PaX Presentation][]
-   [Taking the fun out of smashing the stack][]
-   [Practical Unix Security][]
-   [PaX Memory Protection][] - Linux Journal entry
-   [Advances In Software Attack][]

Secure computing
----------------

-   [Seccomp announcement][] - Secure Computing (seccomp) patch announcement (external link)

Got some good additional papers?
--------------------------------

If you have some relevant papers that would be suitable for this site, please drop [me][] an email.

  [Scut's formatstring paper]: https://overthewire.org/wargames/blacksun/papers/formatstring-1.2.tar.gz
  [Advances in format string exploitation]: https://overthewire.org/wargames/blacksun/papers/p59-0x07.txt
  [Format bug analysis]: https://overthewire.org/wargames/blacksun/papers/format-bug-analysis.pdf
  [Vulnerabilities in your code - Format Strings]: https://overthewire.org/wargames/blacksun/papers/core_format_strings.pdf
  [The Mystery of Format String Exploitation]: https://overthewire.org/wargames/blacksun/papers/rebel-formatstring.txt
  [Once upon a free()]: https://overthewire.org/wargames/blacksun/papers/p57-0x09
  [Vudo - An object superstitiously believed to embody magical powers]: https://overthewire.org/wargames/blacksun/papers/p57-0x08
  [Advanced Doug lea's malloc exploits]: https://overthewire.org/wargames/blacksun/papers/p61-0x06_Advanced_malloc_exploits.txt
  [Malloc Maleficarum]: https://overthewire.org/wargames/blacksun/papers/MallocMaleficarum.txt
  [Framepointer overwrites]: https://overthewire.org/wargames/blacksun/papers/P55-08
  [Bypassing PaX ASLR protection]: https://overthewire.org/wargames/blacksun/papers/p59-0x09.txt
  [The advanced return-into-lib(c) exploits: PaX case study]: https://overthewire.org/wargames/blacksun/papers/p58-0x04
  [PaX documentation]: http://pax.grsecurity.net/docs/
  [Smash the stack - Advanced bufferoverflow methods]: https://overthewire.org/wargames/blacksun/papers/smash_the_stack_advanced_bufferoverflow_methods.txt
  [A Solution To Red Hat PIE Protection]: http://www.hackinthebox.org/print.php?sid=15604
  [How to Exploit Overflow Vulnerability Under Fedora Core]: http://neworder.box.sk/newsread.php?newsid=13007
  [Stack Smashing Protection homepage]: http://www.research.ibm.com/trl/projects/security/ssp/
  [Bypassing StackGuard and StackShield]: https://overthewire.org/wargames/blacksun/papers/p56-0x05
  [Four different tricks to bypass StackShield and StackGuard protection]: https://overthewire.org/wargames/blacksun/papers/StackguardPaper.pdf
  [Defeating compiler-level buffer overflow protection]: https://overthewire.org/wargames/blacksun/papers/alexander0506.pdf
  [x86-64 buffer overflow exploits and the borrowed chunks exploitation technique]: https://overthewire.org/wargames/blacksun/papers/no-nx.pdf
  [A Comparison of Buffer Overflow Prevention Implementations and Their Weaknesses]: https://overthewire.org/wargames/blacksun/papers/Buffer_Overflow_Prevention.ppt
  [Spender's PaX Presentation]: https://overthewire.org/wargames/blacksun/papers/PaX-presentation.ppt
  [Taking the fun out of smashing the stack]: https://overthewire.org/wargames/blacksun/papers/smashing.sxi
  [Practical Unix Security]: https://overthewire.org/wargames/blacksun/papers/practical_unix_security.pdf
  [PaX Memory Protection]: https://overthewire.org/wargames/blacksun/papers/PaX_Memory_Protection.pdf
  [Advances In Software Attack]: https://overthewire.org/wargames/blacksun/papers/advancesinsoftwareattacks.pdf
  [Seccomp announcement]: http://kerneltrap.org/node/4005
  [me]: mailto:andrewg@felinemenace.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

This list is a curated syllabus for Blacksun, and it is useful for anyone studying exploitation.

### How to use this list

- **Start with the bug class you are about to face.** Format strings for Level 0; stack overflows and frame-pointer overwrites for Level 1; heap papers for Level 4.
- **Read the historical papers for ideas,** not as current recipes. The page itself warns that later glibc versions added checks that defeat some older heap attacks.
- **Read the defence documents too.** Understanding how PaX, Execshield, StackGuard and the NX bit work tells you exactly what each protection does and does not stop.
- **Then read the general papers and presentations,** which give a wider view of the field.
- **Secure computing.** The final section collects material on building safer systems, the other side of the same coin.

### A suggested order

1. A format-string paper (Scut's is the class paper).
2. Heap exploitation classics, then the more recent glibc-specific work.
3. Frame-pointer overwrites.
4. ASLR, PaX and Execshield documentation.
5. Stack-protection and hardware-protection (NX bit) papers.

### Contributing

The list ends with an invitation to email the maintainer with other good papers.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../">Blacksun overview</a></nav>

</section>

<!-- study-guide:end -->
