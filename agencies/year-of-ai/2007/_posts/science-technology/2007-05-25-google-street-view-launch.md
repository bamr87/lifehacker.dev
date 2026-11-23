---
title: Google Street View launch
date: 2007-05-25
categories:
- Science & Technology
tags:
- web platforms
- emerging tech
excerpt: 'Google Street View officially launched on May 25, 2007, as a feature integrated into Google Maps, providing users with panoramic street-level imagery of urban environments. The service debuted with coverage of five major U.S. cities: San Francisco, Las Vegas, Denver, Miami, and New York…'
preview: "/images/previews/science-technology.svg"
permalink: "/news/science-technology/google-street-view-launch/"
---

**Key Figures**: Luc Vincent (Engineering Director, Street View); Larry Page (Google co-founder); Google Maps team

## Summary

Google Street View officially launched on May 25, 2007, as a feature integrated into Google Maps, providing users with panoramic street-level imagery of urban environments. The service debuted with coverage of five major U.S. cities: San Francisco, Las Vegas, Denver, Miami, and New York City. The technology employed custom camera rigs mounted on vehicles, featuring multiple lenses arranged to capture 360-degree panoramic views. Images were captured at regular intervals along streets and automatically stitched together using computer-vision algorithms to create seamless virtual street exploration. GPS and inertial measurement unit (IMU) data synchronized image capture with geographic location, enabling precise mapping of the panoramic content.

Throughout 2007, Google rapidly expanded Street View coverage across the United States. By August, additional cities including Los Angeles, San Diego, Houston, and Orlando were added. October 2007 saw expansion to Portland, Phoenix, Tucson, Chicago, Pittsburgh, and Philadelphia, followed by December 2007 additions including Dallas, Fort Worth, Minneapolis, Saint Paul, Indianapolis, Detroit, Providence, Boston, and Hartford. This domestic rollout established Street View as a major component of Google's mapping strategy before any international deployment. The service generated substantial traffic to Google Maps.

## Technical Architecture

The first-generation Street View camera system, developed under Google engineering director Luc Vincent, mounted a multi-lens array atop specially modified vehicles. The rig deployed at launch — known internally as the R2 — was a ring, or "rosette," of eight 11-megapixel cameras with wide-angle lenses pointed in different directions, capturing images at intervals along each street segment. The multiple images were combined through a process called spherical image stitching, creating equirectangular projection images that a browser could render as an interactive 360-degree panorama.

GPS receivers tracked vehicle position to sub-meter accuracy using differential GPS correction, while IMU sensors recorded tilt, pitch, and yaw to compensate for camera movement over uneven road surfaces. Custom software correlated the image timestamps with GPS coordinates, enabling Google to anchor each panoramic frame to a precise map position. The entire pipeline — from raw image capture to web-deliverable panorama — involved tens of thousands of hours of compute time to process the initial five-city deployment, representing one of the largest photogrammetric processing efforts undertaken to that point.

Street View images were rendered in users' browsers via a plugin-free Flash-based viewer in 2007, before later transitioning to WebGL and HTML5. The launch predated widespread smartphone adoption (the [iPhone Launch]({{ '/news/science-technology/iphone-launch/' | relative_url }}) occurred just five weeks after Street View's debut), so the initial product targeted desktop web users. Mobile Street View access would become a major use case after iOS and Android integration in subsequent years.

## 2007 U.S. Expansion Timeline

| Date | Cities Added |
|------|-------------|
| May 25, 2007 | San Francisco, Las Vegas, Denver, Miami, New York City |
| August 2007 | Los Angeles, San Diego, Houston, Orlando |
| October 2007 | Portland, Phoenix, Tucson, Chicago, Pittsburgh, Philadelphia |
| December 2007 | Dallas, Fort Worth, Minneapolis, St. Paul, Indianapolis, Detroit, Providence, Boston, Hartford |

By the end of 2007, Street View covered the street networks of approximately 30 major U.S. metropolitan areas, with an estimated total driving distance of several hundred thousand miles of road captured. International expansion began in 2008, starting with Australia, Japan, and France.

## Privacy Controversies and Policy Response

The launch immediately sparked privacy concerns that would shape the service's long-term evolution. Within weeks of the May 25 debut, media outlets published images captured by Street View showing identifiable individuals in sensitive situations: a man leaving an adult entertainment establishment in San Francisco, a woman sunbathing in her backyard, children playing in front of their homes, and vehicle license plates. By June 2007, The New York Times, the San Francisco Chronicle, and technology blogs widely reported on the emerging privacy controversy.

Privacy advocacy groups including the Electronic Privacy Information Center (EPIC) filed formal complaints with the Federal Trade Commission in 2007, arguing that Google had not adequately informed individuals that their images would be captured and published. Individual complainants used Google's reporting tools — launched shortly after Street View itself — to request removal of specific images. Google responded by implementing automated face-blurring technology by 2008 and extending automatic license-plate blurring.

International deployments encountered even stronger legal pushback. Germany's data protection authorities investigated Street View from 2010 onward, and several German localities voted to opt out of coverage. In 2012, the UK's Information Commissioner's Office found that Street View vehicles had inadvertently captured payload data from unsecured Wi-Fi networks — a revelation that led to enforcement actions and policy changes across multiple countries. The 2007 U.S. launch thus initiated a long-running global negotiation between geospatial data collection and personal privacy rights.

## Significance

Google Street View expanded web-based geographic mapping by adding wide-scale street-level imagery to online maps. It extended Google Maps from a two-dimensional directional tool into a ground-level view and set a widely adopted standard for interactive online maps. By allowing users to view locations remotely, Street View built a large visual archive of cities and neighborhoods accessible to users worldwide.

The 2007 launch also demonstrated how a single technology product could reshape multiple fields simultaneously: urban planning, real estate (enabling remote property assessment), tourism, emergency response (pre-mission reconnaissance), and cultural preservation (documenting streetscapes before demolition or natural disasters). Google Street View imagery has since been used for academic research in urban studies, public health, and environmental monitoring — purposes its creators did not anticipate at launch.

The privacy tensions introduced in 2007 established a template for subsequent debates about ubiquitous data collection. Street View's controversies foreshadowed the larger privacy discourse around location data, facial recognition, and public surveillance that dominated technology policy discussions throughout the 2010s (see [Facebook Platform]({{ '/news/science-technology/facebook-platform/' | relative_url }}) for the concurrent emergence of social-graph data collection). The launch of Street View just five weeks before the iPhone made smartphones mainstream illustrated how 2007 marked the hinge year when the internet became both spatially comprehensive and personally mobile.

## Sources

- [Google Street View - Wikipedia](https://en.wikipedia.org/wiki/Google_Street_View)
- [Google Street View coverage - Wikipedia](https://en.wikipedia.org/wiki/Google_Street_View_coverage)
- [Inside Google Street View: A decade of exploring your world - Google Blog](https://www.google.com/streetview/anniversary/)
- [A Brief History of Google's Street View Cameras - Trek View](https://www.trekview.org/blog/history-of-google-street-view-cameras/)
