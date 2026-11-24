---
title: "The Sony BMG Copy-Protection Rootkit Scandal"
date: 2005-10-31
categories:
- Science & Technology
tags:
- internet
- law
excerpt: On October 31, 2005, security researcher Mark Russinovich revealed that Sony BMG music CDs silently installed rootkit-style copy-protection software on Windows computers, opening security holes and triggering recalls, lawsuits, and a 2007 FTC settlement.
preview: /images/previews/the-sony-bmg-copy-protection-rootkit-scandal.svg
permalink: "/news/science-technology/sony-bmg-rootkit-scandal/"
---

**Key figures**: Mark Russinovich (security researcher, Sysinternals), Thomas Hesse (President, Global Digital Business, Sony BMG), First 4 Internet (developer of XCP), SunnComm (developer of MediaMax), Greg Abbott (Attorney General of Texas), J. Alex Halderman and Edward Felten (Princeton researchers), the Electronic Frontier Foundation

## Summary

On October 31, 2005, the Windows internals researcher Mark Russinovich published a blog post titled "Sony, Rootkits and Digital Rights Management Gone Too Far," documenting that a Sony BMG music CD had silently installed cloaking software of the kind normally associated with malware. The copy-protection system, called Extended Copy Protection (XCP) and developed by the British firm First 4 Internet, buried itself deep in the Windows operating system and hid any file, process, or registry key whose name began with the prefix `$sys$`. Because it concealed its own presence and could not be removed through ordinary means, Russinovich classified it as a rootkit — a category of stealth software until then chiefly seen in computer intrusions rather than commercial products.

XCP was one of two digital-rights-management (DRM) schemes Sony BMG had placed on its discs. The second, MediaMax CD-3, was made by the American company SunnComm and appeared on a much larger number of titles. Between them the two systems shipped on tens of millions of CDs. XCP alone was pressed onto roughly 52 titles and about two million discs; MediaMax was distributed far more widely. The systems were designed to limit copying of the audio and to route playback through a bundled software player, but they installed themselves with little or no meaningful disclosure — XCP only after a user accepted an end-user licence agreement that did not describe the rootkit, and MediaMax reportedly installing components even when a user declined the agreement.

## The Security Problem

The core danger was not the copy protection itself but the cloaking mechanism. By hiding everything prefixed with `$sys$`, XCP created a ready-made hiding place that any attacker could exploit: malware authors needed only to name their files with that prefix to render them invisible to users and to many security tools. Within roughly ten days of Russinovich's post, malicious programs exploiting exactly this cloak appeared in the wild, including a backdoor Trojan (variously catalogued as Backdoor.Ryknos or "Stinx-E") that used the `$sys$` prefix to conceal itself. The software also lacked a proper uninstaller, consumed system resources, and used unsafe methods that could crash a machine or leave the CD-ROM drive inoperable if a user attempted a manual removal.

Sony BMG's early remediation compounded the problem. A first "uninstaller" released in early November did not remove the rootkit but merely unmasked its hidden files, and it installed a web-based ActiveX control. Princeton researchers J. Alex Halderman and Edward Felten subsequently showed that this removal component itself opened a severe hole, allowing code from any website the user visited to run on the computer. The MediaMax system was later found to carry its own vulnerabilities.

## Corporate Response

Sony BMG's public handling of the affair became a case study in reputational damage. In a National Public Radio interview on November 4, 2005, Thomas Hesse, president of the company's global digital business, dismissed the concern by asking, "Most people, I think, don't even know what a rootkit is, so why should they care about it?" As criticism intensified and US-CERT — the United States Computer Emergency Readiness Team — issued a warning that XCP used rootkit technology and posed a security threat, the company reversed course. Sony BMG suspended production of XCP-protected discs on November 11, 2005, and on November 15 announced a recall of unsold XCP titles and an exchange programme for consumers who had already bought them. It later released a genuine removal tool and pulled the affected discs from retail shelves.

The episode also exposed licensing problems within the DRM software itself: analysts found that XCP incorporated code from several open-source projects — including the LAME MP3 encoder and the VLC media player — apparently without complying with the terms of their free-software licences.

## Legal Aftermath

Legal consequences followed quickly. On November 21, 2005, Texas Attorney General Greg Abbott sued Sony BMG under the state's newly enacted Consumer Protection Against Computer Spyware Act of 2005 — believed to be the first lawsuit brought under that law — and later broadened the complaint to cover MediaMax. The Electronic Frontier Foundation and private plaintiffs filed class-action suits in New York and California; a settlement announced in late December 2005 offered affected customers cash payments, DRM-free music downloads, and waivers of certain restrictions, and required Sony BMG to stop making the discs and to provide effective uninstallers. In December 2006 the company reached a further settlement with some 39–41 U.S. states and the District of Columbia.

On January 30, 2007, the Federal Trade Commission announced its own settlement. The FTC charged that installing hidden, hard-to-remove software that exposed consumers to security risks was an unfair and deceptive practice under Section 5 of the FTC Act. Under the terms, Sony BMG agreed to reimburse consumers up to $150 to repair damage caused by removing the software, to clearly disclose any content-protection limitations on future CD packaging, and to refrain from installing content-protection software without consumers' consent.

## Significance

The Sony BMG rootkit scandal was a landmark in the debates over digital rights management, computer security, and consumer trust. It demonstrated that aggressive anti-copying measures could actively degrade the security of the machines they ran on, and it hardened public and regulatory skepticism toward invasive DRM at the very moment the recording industry was fighting piracy on other fronts — including its Supreme Court victory months earlier in [MGM v. Grokster]({{ '/news/science-technology/grokster-decision-p2p-liability/' | relative_url }}). The backlash accelerated the industry's retreat from copy-protected CDs and its pivot toward licensed digital distribution, part of the broader shift chronicled in the [digital music revolution]({{ '/news/society-economics/digital-music-revolution/' | relative_url }}). The affair also raised the profile of independent security research: Russinovich's disclosure became a textbook demonstration of how a single technical investigation could force a multinational corporation into a costly recall and regulatory settlement.

## Sources

- [Sony BMG copy protection rootkit scandal — Wikipedia](https://en.wikipedia.org/wiki/Sony_BMG_copy_protection_rootkit_scandal)
- [Sony BMG Settles FTC Charges — U.S. Federal Trade Commission (January 30, 2007)](https://www.ftc.gov/news-events/news/press-releases/2007/01/sony-bmg-settles-ftc-charges)
- [Sony, Rootkits and Digital Rights Management Gone Too Far — Mark Russinovich, Sysinternals (October 31, 2005)](https://learn.microsoft.com/en-us/archive/blogs/markrussinovich/sony-rootkits-and-digital-rights-management-gone-too-far)
- [Lessons from the Sony CD DRM Episode — J. Alex Halderman and Edward W. Felten (2006)](https://cdn.loc.gov/copyright/1201/2006/hearings/sonydrm-ext.pdf)
