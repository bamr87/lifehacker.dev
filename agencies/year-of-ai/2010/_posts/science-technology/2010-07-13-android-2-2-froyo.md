---
title: "Android 2.2 Froyo — Mobile Computing Acceleration"
date: 2010-07-13
categories:
  - Science & Technology
tags:
  - mobile operating system
  - software release
  - smartphone innovation
excerpt: "Google's Android 2.2 Froyo, rolling out to handsets through mid-2010, introduced JIT compilation that roughly doubled performance, plus USB tethering and mobile hotspot features that accelerated Android's competitive position against iOS."
preview: "/images/previews/science-technology.svg"
permalink: "/news/science-technology/android-2-2-froyo/"
---

**Key figures**: Andy Rubin (Android lead, Google VP), Google engineering team, Eric Schmidt (Google CEO)

## Summary

Google released Android 2.2 "Froyo" (Frozen Yogurt) on May 20, 2010, for Nexus One devices, with a broader rollout to other handsets through July and August. The update represented the most significant performance leap the platform had achieved since launch, introducing a Dalvik just-in-time (JIT) compiler that roughly doubled application execution speeds compared to Android 2.1 Éclair. Independent benchmarks on the Nexus One showed the browser JavaScript engine performing approximately 450 percent faster on the SunSpider benchmark after the Froyo update — a jump that closed a major performance gap with Apple's iPhone 3GS and positioned Android favourably ahead of the [iPhone 4's launch in June 2010]({{ '/news/science-technology/iphone-4-launch/' | relative_url }}).

The operating system was also the first widely distributed mobile platform to enable Wi-Fi hotspot functionality and USB tethering natively, without requiring carrier permission or hardware modification. Users could share their cellular data connection with up to eight devices simultaneously via Wi-Fi. This capability was significant because Apple's iOS 4, released the same month as Froyo's Nexus One rollout, did not support personal hotspot. AT&T, the exclusive US carrier for iPhone at the time, blocked the feature even on Android handsets it sold, but manufacturers and Google offered it freely to devices outside carrier control.

## Technical Improvements

The JIT compiler was the architectural centrepiece of Froyo. Earlier Android versions interpreted Dalvik bytecode instruction by instruction; the JIT compiler converted frequently executed code paths into native machine instructions at runtime, eliminating the interpreter overhead for hot code. The practical effect was that CPU-intensive applications, games, and the browser rendered meaningfully faster with no hardware changes.

Additional technical improvements in Froyo included:

- **Flash support**: Adobe Flash 10.1 was integrated into the Android browser, giving Android devices full desktop-class Flash playback at a time when Apple had publicly refused to allow Flash on iOS. Steve Jobs published his open letter "Thoughts on Flash" in April 2010; Froyo's Flash support became a direct competitive counter-argument.
- **Application installation to SD card**: Prior to Froyo, all apps were installed to internal storage. Froyo added the option to install to external SD cards, extending device capacity at a time when most devices shipped with 512 MB of internal storage.
- **Push notifications via Cloud to Device Messaging (C2DM)**: An early version of what would become Google Cloud Messaging, enabling servers to push data and notifications to Android devices efficiently.
- **Improved Exchange support**: Enhanced synchronisation with Microsoft Exchange email and calendars expanded Android's appeal to enterprise users.

## Market Context

The Froyo release landed in an intensely competitive period. The [iPad had launched on April 3, 2010]({{ '/news/science-technology/ipad-launch/' | relative_url }}), redefining tablet computing; the iPhone 4 followed with a Retina display and redesigned chassis; and Android handset makers including HTC, Motorola, and Samsung were releasing multiple competing devices per quarter. By mid-2010, Android held approximately 17 percent of the smartphone market, trailing iOS's roughly 26 percent; by the end of 2010 Android had climbed to 22–25 percent share while gaining on iOS in absolute unit sales.

The Froyo era also established the developer community's confidence in Android as a platform. The performance improvements made complex applications viable, and the Flash support gave developers a bridge from existing web content to mobile. These factors contributed to the Google Play (then Android Market) library growing to more than 80,000 applications by December 2010.

[Instagram's October 2010 launch]({{ '/news/science-technology/instagram-launch/' | relative_url }}) was among the earliest demonstrations of the mobile photo-sharing category that Froyo's performance improvements made feasible on a mass-market scale.

## Legacy

Android 2.2 Froyo is regarded by Android developers and historians as the release that proved Android could match or exceed iOS in technical capability rather than merely compete on price and hardware variety. The JIT compiler architecture it introduced remained foundational until Android 5.0 Lollipop introduced the ART (Android Runtime) ahead-of-time compiler in 2014, replacing Dalvik entirely. Froyo's Wi-Fi hotspot feature eventually became universal across mobile platforms as carriers lifted restrictions.

See also: [iPhone 4 Launch]({{ '/news/science-technology/iphone-4-launch/' | relative_url }}) · [iPad Launch]({{ '/news/science-technology/ipad-launch/' | relative_url }}) · [Instagram Launch]({{ '/news/science-technology/instagram-launch/' | relative_url }}) · [Foursquare and Location Social Networking]({{ '/news/science-technology/foursquare-location-social/' | relative_url }})

## Sources

- [Android Developers Blog — Android 2.2 Platform Highlights](https://android-developers.googleblog.com/2010/05/android-22-froyo-release-announcement.html)
- [Ars Technica — Android 2.2 Froyo: A Thorough Review](https://arstechnica.com/gadgets/2010/07/android-22-froyo-review/)
- [AnandTech — Nexus One Android 2.2 Performance Analysis](https://www.anandtech.com/show/3748/android-22-froyo-analyzed-dalvik-jit-in-detail)
- [Wikipedia — Android version history: 2.2 Froyo](https://en.wikipedia.org/wiki/Android_version_history#Android_2.2_Froyo_(API_8))
