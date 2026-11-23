---
title: Microsoft Kinect for Xbox 360 Launch
date: 2010-11-04
categories:
- Science & Technology
tags:
- consumer tech
- record-breaking
excerpt: Microsoft released the Kinect motion-sensing device for Xbox 360 on November 4, 2010, in North America, followed by a European launch on November 10 and a Japanese launch on November 20. Priced at $149.99 for the standalone sensor and $299.99 bundled with a 4GB Xbox 360, Kinect enabled…
preview: "/images/previews/science-technology.svg"
permalink: "/news/science-technology/kinect-launch/"
---

**Category:** Science & Technology

**Key figures:** Alex Kipman (Kinect inventor, Microsoft), Don Mattrick (President, Interactive Entertainment Business), Kudo Tsunoda (Kinect creative director), Steve Ballmer (Microsoft CEO), Ne-Yo (launch event performer)

## Summary

Microsoft released the Kinect motion-sensing device for Xbox 360 on November 4, 2010, in North America, followed by a European launch on November 10 and a Japanese launch on November 20. Priced at $149.99 for the standalone sensor and $299.99 bundled with a 4GB Xbox 360, Kinect enabled body-tracking, gesture recognition, and voice-command capabilities without any physical controller, marketed under the tagline "You Are the Controller." The device set a Guinness World Record as the fastest-selling consumer electronics device in history, moving 8 million units in its first 60 days — a rate of approximately 133,333 units per day that surpassed the launch-period sales velocity of the iPhone and iPad. By the time Microsoft discontinued the Kinect sensor in 2017, over 35 million units had been sold, and the depth-sensing technology it popularized had become foundational to everything from Apple LiDAR to autonomous vehicle sensing.

## Development History: From Project Natal to Kinect

Kinect's origins lay in a research collaboration between Microsoft and Israeli startup PrimeSense, whose structured-light depth-sensing technology formed the hardware core of the device. PrimeSense's approach used an infrared projector to cast a known dot pattern onto the environment, then computed depth by analyzing how the pattern deformed when reflected — a fundamentally different approach from later time-of-flight (ToF) sensors such as Apple's LiDAR.

Development at Microsoft was led by Alex Kipman, a Brazilian-born engineer who had previously worked on Windows Vista. Kipman's project, internally named "Project Natal," was publicly unveiled on June 1, 2009, at the Electronic Entertainment Expo (E3 2009) in a demonstration video narrated by actor Steven Spielberg. The announcement was among the most anticipated in the show's history: the demo showed players controlling games using only their bodies — steering virtual cars, dodging virtual attacks, and interacting with a virtual pet — with no controller in hand. The reaction from the gaming press was largely ecstatic, though skeptics questioned whether the technology would work reliably in real living rooms.

On June 13, 2010, at E3 2010, Microsoft confirmed the product name "Kinect" (a portmanteau of "kinetic" and "connect"), announced the November launch window, and revealed the $499-million marketing campaign budget — an extraordinary figure comparable to the marketing spend for an entirely new console, not a peripheral. CEO Steve Ballmer appeared at the E3 2010 keynote alongside celebrities including Kobe Bryant to demonstrate the device.

## Technical Architecture

The Kinect sensor bar contained several integrated subsystems:

- **RGB camera**: A 640×480 color camera operating at 30 frames per second, used for face recognition, gesture capture, and video chat.
- **Depth sensor**: A PrimeSense-based infrared projector paired with an infrared camera, generating a depth map of the environment at 30 fps. The original Kinect could detect skeletal positions at distances of approximately 1.2–3.5 meters.
- **Microphone array**: Four microphones arranged along the bottom of the sensor bar, capable of isolating voice commands from background noise and localizing sound direction — enabling Xbox 360 users to say "Xbox, play" or navigate menus entirely by voice.
- **Motorized tilt**: A small motor allowed the sensor bar to tilt up or down automatically to find and track players, accommodating different room configurations.
- **Skeleton tracking**: The device could simultaneously track up to two active players, resolving 20 skeletal joints per person at 30 fps. The underlying algorithm — "real-time human pose recognition from a single depth image" — was developed by researchers Jamie Shotton, Andrew Fitzgibbon, and colleagues at Microsoft Research Cambridge, and published as a landmark computer vision paper in 2011.

The skeleton-tracking algorithm was notable not only for its accuracy but for its efficiency: it ran in real-time on standard Xbox 360 hardware (3.2 GHz IBM PowerPC triple-core) without dedicated processing co-processors, a computational achievement that contributed significantly to Kinect's academic and developer impact.

## Launch and Marketing

The $500-million marketing campaign — by comparison, the original Xbox 360 launch in 2005 had a $200-million campaign — spanned television, print, digital, and experiential channels. Corporate partnerships with Burger King and Pepsi embedded Kinect promotion in mass-market fast-food and beverage campaigns. A launch event in New York's Times Square on the evening of November 3, 2010 featured a performance by R&B artist Ne-Yo and drew significant media attention.

The launch software library included:

- **Kinect Adventures** (bundled with device): Five minigames demonstrating the range of body-tracking capabilities, from virtual whitewater rafting to bubble-popping.
- **Dance Central** (Harmonix): Widely regarded as the highest-quality launch title, using full-body tracking to score dancers against choreography. It became the best-selling Kinect title and prompted a franchise.
- **Your Shape: Fitness Evolved** (Ubisoft): A fitness application that scanned the player's body silhouette in real time and provided personalized exercise feedback, demonstrating non-gaming use cases.
- **Kinectimals** (Frontier Developments): A virtual pet game targeting young children, exploiting the emotional response to voice-and-gesture interaction with animated animal characters.

Within 60 days, Kinect had sold 8 million units. By February 2011 — approximately 90 days after launch — it had moved 10 million units. Microsoft's internal forecast had been 5 million units for the 2010 holiday season, meaning the actual result exceeded projections by 60 percent.

## The Open-Source Driver and Hacker Community

Six days after the North American launch — on November 10, 2010 — Spanish hacker Héctor Martín Cantero (known as "marcan") released the first open-source drivers for Kinect, claiming a $3,000 bounty posted by electronics retailer Adafruit Industries. The driver allowed the depth data to be accessed on non-Xbox computers, unlocking the sensor as a general-purpose depth camera at a price point (under $150) an order of magnitude cheaper than comparable industrial depth sensors.

The result was an explosion of non-gaming applications within weeks of launch: researchers at MIT, Carnegie Mellon, and dozens of other universities repurposed Kinect for robotic navigation, 3D body scanning, surgical visualization, gesture-based musical instruments, and interactive art installations. Microsoft initially issued ambiguous statements about whether such use was permitted, then reversed course and embraced the hacker community: on June 16, 2011, Microsoft released an official Kinect for Windows SDK (beta), enabling non-commercial development. The commercial SDK followed in February 2012, alongside a dedicated "Kinect for Windows" sensor variant. This community-to-commercial pipeline — a consumer device hacked into a research platform and then formally productized — became a model for subsequent hardware companies.

## Market Context: The 2010 Motion-Control Wars

Kinect launched into a competitive landscape defined by Nintendo's Wii, which had demonstrated since 2006 that motion-based gaming could attract non-traditional gaming audiences. By 2010, Nintendo had sold more than 70 million Wii consoles, and both Sony and Microsoft were racing to capture the casual and family gaming segments Wii had opened.

Sony launched the PlayStation Move on September 19, 2010 — a wand-based motion controller that required a PlayStation Eye camera. Unlike Kinect, Move tracked a glowing sphere visible to the camera, providing high accuracy but retaining a physical controller. The competing approaches represented two design philosophies: Sony's incremental improvement on existing motion-control (more precise than Wii), versus Microsoft's bet on controller-free interaction as a paradigm shift.

In the 2010 holiday season, Kinect significantly outsold PlayStation Move and extended Xbox 360's competitive position against both the Wii and PlayStation 3. The controller-free design proved particularly compelling for non-gaming applications (fitness, family entertainment) even as it limited precise control for core-gaming genres.

## Long-Term Technology Legacy

Kinect's depth-sensing architecture influenced a generation of subsequent hardware:

- **Intel RealSense**: Intel's camera division, launched in 2014, produced a series of depth-sensing cameras for laptops and PC peripherals using structured-light and stereo-vision approaches directly analogous to Kinect.
- **Apple Face ID and LiDAR**: Apple's 2017 iPhone X introduced Face ID, which used a structured-light depth sensor (TrueDepth camera) for facial recognition — the same fundamental principle as Kinect. Apple later acquired PrimeSense (the Kinect chip supplier) in November 2013 for an estimated $345 million, and the acquired technology's lineage runs through Face ID and the iPad Pro's LiDAR scanner (launched March 2020).
- **Azure Kinect**: Microsoft released a successor sensor, the Azure Kinect DK (Developer Kit) in June 2019, featuring a Sony time-of-flight depth sensor, a 12-megapixel RGB camera, and a seven-microphone circular array, targeting cloud-connected AI and mixed-reality development rather than gaming.
- **HoloLens**: Microsoft's mixed-reality headset, announced in January 2015, was developed by the same team (led by Alex Kipman) that built Kinect, and used depth-sensing to map environments for holographic overlay.

Kinect for Xbox 360 was discontinued in October 2017, and the Xbox One's bundled Kinect 2.0 (launched 2013) was made optional in 2014 and effectively discontinued by 2016. Despite the product's commercial sunset, the technical and cultural impact of its 2010 launch — bringing depth-sensing to mass-market homes at consumer prices and igniting a research community — proved more durable than its own product lifecycle.

## Significance

The Kinect launch of November 4, 2010 represented a convergence of several significant trends: the normalization of controller-free human-computer interaction, the power of an open-source hacking community to expand a consumer device's applications far beyond its designer's intentions, and the trickle-up path from mass-market consumer electronics to advanced research platforms. Kinect's Guinness record (8 million units in 60 days) demonstrated that non-traditional gaming peripherals could achieve iPhone-level commercial velocity when backed by adequate marketing and positioned as lifestyle products rather than gamer accessories. Though Kinect itself was discontinued after seven years, the depth-sensing paradigm it popularized is now embedded in billions of smartphones, tablets, autonomous vehicles, and augmented-reality systems — making the 2010 launch an underappreciated inflection point in the history of human-computer interaction.

## Sources

- [Kinect — Wikipedia](https://en.wikipedia.org/wiki/Kinect)
- [Microsoft News: "The Future of Entertainment Starts Today" (November 4, 2010)](https://news.microsoft.com/source/2010/11/04/the-future-of-entertainment-starts-today-as-kinect-for-xbox-360-leaps-and-lands-at-retailers-nationwide/)
- [The Hollywood Reporter: "Microsoft's Kinect Xbox 360 Sets Guinness Record as Fastest-Selling Consumer Electronics Device"](https://www.hollywoodreporter.com/business/digital/microsoft-s-kinect-xbox-360-165990/)
- [Engadget: "Ten years on, Kinect's legacy goes beyond Xbox"](https://www.engadget.com/kinect-10-years-retrospective-150011349.html)
- [MIT Technology Review: "The Kinect Revolution" (2011)](https://www.technologyreview.com/2011/03/15/193581/the-kinect-revolution/)
- [Shotton et al., "Real-time Human Pose Recognition in Parts from Single Depth Images" — Microsoft Research (CVPR 2011)](https://www.microsoft.com/en-us/research/publication/real-time-human-pose-recognition-in-parts-from-single-depth-images/)
