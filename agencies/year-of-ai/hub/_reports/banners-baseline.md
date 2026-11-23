# Banner quality baseline

Generated 2026-10-20T05:13:49Z by `scripts/audit-banners.rb` (ADR-0008 Phase 0) over 13 member(s) of `year-of-ai`. The JSON twin [`banners-baseline.json`](banners-baseline.json) carries every banner's row; `scripts/reillustrate.rb` works the backlog from it.

## KPIs

| KPI | Baseline |
| --- | --- |
| Banners | 456 |
| Strict-clean | 0.4% |
| …failing only on `<text>` | 79.2% |
| Mean critic `overall` (n=20) | 5.3 |
| `thumbnail_holds` | 0.0% |
| Critic cost (list price, sample) | — (CLI login: no usage reported) |

## Per repo

| Repo | Banners | With `<text>` | Strict-clean | Clean but `<text>` | Lint errors | Median KB | `<filter>` | Gradients |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1776 | 35 | 100.0% | 0.0% | 80.0% | 0.0% | 19.3 | 57.1% | 100.0% |
| 1777 | 31 | 100.0% | 0.0% | 71.0% | 6.5% | 16.0 | 67.7% | 100.0% |
| 1778 | 36 | 100.0% | 0.0% | 77.8% | 2.8% | 17.4 | 61.1% | 100.0% |
| 2005 | 37 | 100.0% | 0.0% | 83.8% | 0.0% | 16.7 | 75.7% | 100.0% |
| 2006 | 34 | 100.0% | 0.0% | 82.4% | 0.0% | 15.2 | 70.6% | 94.1% |
| 2007 | 44 | 100.0% | 0.0% | 84.1% | 0.0% | 15.7 | 79.5% | 100.0% |
| 2008 | 35 | 100.0% | 0.0% | 80.0% | 2.9% | 17.1 | 68.6% | 97.1% |
| 2009 | 34 | 100.0% | 0.0% | 76.5% | 5.9% | 16.4 | 73.5% | 100.0% |
| 2010 | 38 | 100.0% | 0.0% | 81.6% | 2.6% | 14.7 | 73.7% | 100.0% |
| 2011 | 45 | 97.8% | 2.2% | 84.4% | 0.0% | 15.9 | 77.8% | 97.8% |
| 2012 | 35 | 97.1% | 2.9% | 71.4% | 8.6% | 17.2 | 71.4% | 100.0% |
| 2013 | 38 | 100.0% | 0.0% | 84.2% | 0.0% | 16.3 | 76.3% | 97.4% |
| 2014 | 14 | 100.0% | 0.0% | 50.0% | 7.1% | 13.0 | 57.1% | 100.0% |
| **all** | **456** | **99.6%** | **0.4%** | **79.2%** | **2.4%** | **16.2** | **71.1%** | **98.9%** |

63 banner(s) are shared section placeholders (carried by more than one article) and 42 are carried by no article at all — neither is critiqued per article or backfilled. 5192 `<text>` elements in all. Strict lint treats any `<text>` as a failure (fonts are not guaranteed at render time); the "clean but `<text>`" column is what the illustration loop's text→paths step fixes mechanically, without a model call.

## Lint findings

| Count | Finding (numbers normalized) |
| ---: | --- |
| 5192 | <text> present — fonts are not guaranteed at render time. Convert to paths for distribution. |
| 82 | no <title> as first child (screen readers, and it shows as a tooltip) |
| 11 | reference(s) to missing id(s): … — gradient or clipPath will silently render as black/none |

## Critic sample (20/20, model `claude-sonnet-5-5`, seed `adr-0008`)

| Banner | Overall | Thumbnail | Next change |
| --- | ---: | :---: | --- |
| 2007/october-2007-california-wildfires.svg | 4.5 | fails | Move the flame sprites out from behind the text panels. Put one large, bright, flat-colored pixel fire with a dark silhouetted hill/house skyline across the empty lower-middle band |
| 2010/tesla-ipo-the-first-major-automaker-public-offerin.svg | 4.5 | fails | Rebuild the banner as one chunky pixel-grid composition. Drop the stat boxes, ticker, TSLA box and EXCHANGE badge. Render a large, bright, blocky-pixel red Roadster with a visible  |
| 2012/2012-london-olympics-technology-broadcasting.svg | 4.5 | fails | Pull the headline and date out of the TV's area. Shorten the title to a large pixel-font '2012 LONDON' in the top-left with a smaller 'TECH & BROADCAST' below. Move the TV down and |
| 1776/john-dickinson-and-the-articles-of-confederation-t.svg | 5.0 | fails | Cut the parchment to about half its width and enlarge Dickinson. Then replace the tiny '9/13' counter with a large, bright, high-contrast '9/13' (about 3x current size) centered in |
| 1776/lord-north-frederick-north-earl-of-guilford-in-177.svg | 5.0 | fails | Cut the HUD clutter (the meter, YEAR/STAGE text, the 'BRITAIN vs COLONIES' line and the subtitle) and brighten the scene: a saturated sky-blue or teal background in place of the ne |
| 1778/raquel-premieres-in-madrid-spanish-neoclassical-tr.svg | 5.0 | fails | Rebuild the bottom-left title panel. Make it taller, move the 'MADRID · OCT 30, 1778' line fully inside it with clear padding above 'RAQUEL', and set 'RAQUEL' much larger in bright |
| 2012/fukushima-daiichi-and-japan-s-2012-nuclear-restart.svg | 5.0 | fails | Replace the gold blob at upper right with a clear, high-contrast pixel icon (a bright yellow-and-black radiation trefoil, or a cooling tower with a glowing core). At the same time, |
| 2006/aaron-spelling-dies.svg | 5.5 | fails | Remove or fix the floating HOLLYWOOD lettering, either by deleting it or by redrawing it as a clean block-pixel sign with a correct M on the hillside. Then enlarge the headline and |
| 2007/transformers.svg | 5.5 | fails | Move the yellow car up and out of the title band, or shrink it and place it clearly above the title baseline, so the wheels no longer overlap the 'TRANSFORMERS' lettering. Then swa |
| 2011/rupert-murdoch-s-parliamentary-testimony-and-media.svg | 5.5 | fails | Cut the scene to one large focal group: scale the two figures and desk up about 2x as the hero, with a distinct white-haired Murdoch silhouette in a bright color against the lit Pa |
| 1777/the-danbury-raid-and-battle-of-ridgefield.svg | 5.5 | fails | Replace the grey block-cluster ship and the low-contrast bottom HUD band with a clean, higher-contrast pixel silhouette of a ship (dark hull, two light sails) positioned clear of t |
| 1776/astronomy-and-navigation-in-1776-the-science-of-fi.svg | 5.5 | fails | Enlarge the ship to about twice its size and centre it, with a bigger, higher-contrast pixel-grid hull and cleaner sails. Remove the tiny captions and the ghost '1776', and make th |
| 2010/ios-4-and-the-app-store-ecosystem.svg | 5.5 | fails | Redraw the whole banner on a coarse pixel grid. Use crisp-edged rects with shape-rendering=crispEdges, a chunky blocky pixel typeface for the title built from rects or a pixel font |
| 2011/un-climate-change-conference-cop17-durban-platform.svg | 5.5 | fails | Cut the clutter (timeline strip, hand, red torch figure, dark clouds, top subtitle) and enlarge the title. Re-letter it as blocky pixel-grid glyphs about 2x taller on the dark pane |
| 2009/transformers-revenge-of-the-fallen-theatrical-rele.svg | 5.5 | fails | Redraw the Fallen and the grey middle robot with hard-edged pixel blocks. Give the Fallen a lighter rim or fill (for example bright red and orange with a gold horn highlight) so it |
| 1777/the-hudson-river-campaign-capture-of-forts-clinton.svg | 5.5 | fails | Redraw the scene larger and brighter on a strict pixel grid. Scale the forts and the lead ship up to about 2x, fill the empty sky with a bright gradient or a sunset band, and drop  |
| 2010/new-start-treaty-signed-in-prague.svg | 5.5 | fails | Delete the footer text and the two 1,550 boxes, and enlarge the title to a bold blocky bitmap-style font, built from rects or a pixelated font with shape-rendering crispEdges and n |
| 2010/smartphone-platform-wars-android-ascendant-in-2010.svg | 5.5 | fails | Remove the overlapping [2010] and SCORE badges (or stack them cleanly above the Android's head with a gap), then enlarge the Android bot and the title block and switch the title to |
| 2012/2012-presidential-debates-and-vice-presidential-de.svg | 6.0 | fails | Remove the glow, blur and magenta offset on the title and numerals and set them in a chunky blocky pixel typeface at a larger size with a hard 1-2px dark drop shadow. The headline  |
| 2007/kanye-west-s-graduation.svg | 6.0 | fails | Fix the stat line: widen the yellow box to span the full text with at least 12px of padding on each side (or shorten the text to '957,000 #1 BILLBOARD'), and make sure it does not  |

## Method

- Lint: `preview_generator.py --inspect` — the engine's strict lint, identical to the illustration loop's commit gate (viewBox, role/title, raster or network payloads, dangling `url(#…)`, precision, the size budget, and `<text>`).
- Renders: npx at 600px and 120px; contact sheets are written to the scratch dir (`audit/sheets/`), not committed.
- Critic: `--inspect --critic` renders each sampled banner at 1536px and 120px and asks `claude-sonnet-5-5` for the loop's structured critique against the article it illustrates. The sample is the first N banners by SHA-256 of `seed:repo/name`, so a re-run with the same seed scores the same banners.
