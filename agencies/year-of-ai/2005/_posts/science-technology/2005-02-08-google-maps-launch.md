---
title: "Google Maps launches"
date: 2005-02-08
categories:
  - Science & Technology
tags:
  - internet
  - software
  - cartography
  - google
excerpt: "Google released Google Maps as a limited beta on February 8, 2005, introducing interactive web-based mapping and satellite imagery that would revolutionize geographic information access and launch a trillion-dollar location-services industry."
preview: /images/previews/google-maps-launches.svg
permalink: "/news/science-technology/google-maps-launch/"
---

**Key figures**: Google Inc., Lars Rasmussen, Jens Rasmussen, Noel Gordon, Stephen Ma (Where 2 Technologies), John Hanke (Keyhole)

## Background: Building the Foundation

Google Maps did not emerge from within Google itself. Its core technology originated at **Where 2 Technologies**, a Sydney-based startup founded by Danish brothers Lars and Jens Rasmussen with colleagues Noel Gordon and Stephen Ma. The team had been working on a downloadable desktop mapping client when Google acquired the company in **2004** for an undisclosed sum — one of Google's earliest acquisitions.

Around the same time, in October 2004, Google acquired **Keyhole, Inc.** — a startup backed in part by the CIA's venture arm In-Q-Tel, whose flagship product, Earth Viewer, provided zoomable satellite and aerial imagery of the Earth's surface. John Hanke, Keyhole's co-founder, joined Google and would eventually lead the geographic products division. The fusion of Where 2's interactive street-mapping engine with Keyhole's satellite imagery became the technical core of Google Maps.

A third piece of the puzzle was already inside Google: a mapping data relationship with **Navteq**, which supplied the street-level geographic data that powered routing and address lookup.

## February 8, 2005: Launch

On **February 8, 2005**, Google released Google Maps as a **limited beta**, initially serving the United States only. The interface was a revelation. Prior mapping services — MapQuest (launched 1996), Yahoo Maps, and Microsoft's MapPoint — operated on a static request-response model: a user typed an address, submitted a form, and received a fresh page load with a static GIF or PNG image of a map. Panning or zooming required another full page reload.

Google Maps used **AJAX** (Asynchronous JavaScript and XML) to load map tiles continuously in the background as a user dragged the map, creating the first mass-market "slippy map" experience on the web. Tiles — small 256×256 pixel images — were pre-fetched for adjacent areas, so panning felt instantaneous. The draggable interface required no instructions to understand; users discovered it intuitively within seconds.

The satellite imagery layer, inherited from Keyhole, allowed users to toggle between a road map and an overhead photographic view — an unprecedented feature for a free consumer product. Coverage varied widely by geography (urban centers had high-resolution imagery; rural and international areas were often blurry or absent), but the effect was viscerally compelling. Within weeks of launch, the site was viral in technology circles.

### Technical Architecture

The underlying engineering choice was consequential beyond mapping. Google Maps's AJAX implementation demonstrated that richly interactive web applications — what would later be called "Web 2.0" — were technically feasible in standard browsers without plugins. The launch coincided with and accelerated a broader industry shift toward browser-based application design. Jesse James Garrett coined the term "AJAX" in an influential article published on February 18, 2005 — ten days after Maps launched — explicitly citing Google's products as the exemplars.

## The Public API: June 2005

On **June 29, 2005**, Google released the **Google Maps JavaScript API**, allowing third-party developers to embed interactive Google Maps into their own websites for free. The API was the product's second act, and arguably the more important one.

Within weeks, independent developers had built dozens of "mashups" — sites that layered data on top of Google Maps. Paul Rademacher's **HousingMaps.com** (launched in April 2005, before the official API, by reverse-engineering the Maps protocol) let users browse Craigslist real-estate listings on a map rather than a text list — demonstrating a new category of application. Adrian Holovaty's **ChicagoCrime.org** mapped Chicago Police Department crime data spatially. By year-end 2005, the developer community had built thousands of API-powered applications.

Google Maps had $0 in direct revenue in 2005 but was rapidly becoming a platform — the geographic layer underpinning the web.

## Competition and Market Displacement

At launch, **MapQuest** held roughly 70% of the U.S. online mapping market, followed by Yahoo Maps and Microsoft's mapping service. Google Maps displaced them with unusual speed. By late 2005, comScore data showed Google Maps had captured significant market share; by 2007, it was the dominant U.S. mapping service by traffic. MapQuest, acquired by AOL in 2000 for $1.1 billion, would never recover market leadership.

Yahoo responded in 2005 with its own AJAX mapping upgrade, and Microsoft launched **Windows Live Local** (later Bing Maps) with competitive features including a birds-eye oblique-view imagery system. Neither dislodged Google Maps as the default.

## Geographic Expansion

- **United Kingdom and Canada**: Added in April 2005, including UK-specific transit overlays.
- **Google Earth**: On **June 28, 2005**, the day before the API launch, Google released Google Earth — the consumer successor to Keyhole's Earth Viewer — as a free download, reaching 1 million downloads within days.
- **Satellite imagery expansion**: By late 2005, most major cities worldwide had high-resolution satellite coverage.
- **Transit integration**: Google began integrating public transit data feeds in late 2005 in partnership with transit agencies.

## Significance and Legacy

Google Maps transformed the relationship between digital information and physical space. Its most durable contribution was establishing the **map as a default information layer** for the entire internet. News events, restaurant reviews, social connections, and commercial listings all became anchored to geographic coordinates in ways that pre-Maps web design had not attempted.

The service also pioneered **satellite imagery as a consumer product**, triggering privacy debates that persist today. In 2005, the U.S. government quietly requested that Google blur imagery of the White House, the U.S. Capitol, and other sensitive facilities — a request Google declined, pointing out that the imagery was already commercially available from satellite vendors.

The long-run effects were structural:

- **Mobile**: When Google released Google Maps for mobile in 2006 and added **free turn-by-turn navigation** to Android on October 28, 2009, it triggered the collapse of dedicated GPS device sales. On the day of the announcement, Garmin's stock fell about 16% and TomTom's about 21%, wiping out roughly $1.2 billion in combined market value; standalone navigation-device makers never recovered their earlier growth.
- **Location-based services**: Foursquare (2009), Uber (2009), Airbnb (2008), and Pokémon GO (2016) all relied on the Maps API as core infrastructure.
- **Advertising**: Location data became Google's second most valuable advertising signal after search intent. Google's "local pack" — the map-and-business-listing block that appears above organic search results — commands premium advertising rates and drives significant portions of Google's revenue.

By 2023, Google Maps had approximately **1 billion monthly active users**, with more than 40 million businesses listed on the platform.

## Related Topics

- [YouTube founded (2005)]({{ '/news/science-technology/youtube-founded/' | relative_url }}) — the other 2005 web platform that redefined how people share media
- [English Wikipedia passes half a million articles (2005)]({{ '/news/science-technology/wikipedia-500000-articles/' | relative_url }}) — a parallel 2005 milestone in open, collaborative web infrastructure
- [Digital music revolution (2005)]({{ '/news/society-economics/digital-music-revolution/' | relative_url }}) — the broader 2005 shift toward web-native consumer services
- [MGM v. Grokster decided (2005)]({{ '/news/science-technology/grokster-decision-p2p-liability/' | relative_url }}) — a defining 2005 legal fight over internet-era technology
- [PlayStation Portable launches (2005)]({{ '/news/science-technology/psp-launch/' | relative_url }}) — another 2005 product that folded connectivity and mapping into a consumer device

## Sources

- [Wikipedia: Google Maps](https://en.wikipedia.org/wiki/Google_Maps)
- [BBC: Google Maps: Ten Years of Changing How We See the World](https://www.bbc.com/news/technology-31500999)
- [Garrett, Jesse James. "Ajax: A New Approach to Web Applications." Adaptive Path, February 18, 2005](https://web.archive.org/web/20080702075113/http://www.adaptivepath.com/ideas/essays/archives/000385.php)
- [Wired: The Renegade Google Maps Hacker](https://www.wired.com/2005/04/the-renegade-google-maps-hacker/)
- [TechCrunch: Google Maps API Launches](https://techcrunch.com/2005/06/29/google-maps-api-launches/)
