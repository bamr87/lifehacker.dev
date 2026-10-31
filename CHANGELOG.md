# Changelog

## [0.2.1](https://github.com/bamr87/lifehacker.dev/compare/v0.2.0...v0.2.1) (2026-10-31)


### Fixed

* **brand:** accept the quoted 10x price ratio in the GPT-6.1 Terra dispatch ([#772](https://github.com/bamr87/lifehacker.dev/issues/772)) ([6cf924b](https://github.com/bamr87/lifehacker.dev/commit/6cf924b263553285726501249c1f65c093c653b7))

## [0.2.0](https://github.com/bamr87/lifehacker.dev/compare/v0.1.0...v0.2.0) (2026-10-30)


### Added

* **ai:** generalize the runner into the shared ai-runner kit ([990ca6c](https://github.com/bamr87/lifehacker.dev/commit/990ca6c0c13709eb6b4b1b9eca0534aaf68cc2f4))
* **ai:** the shared ai-runner kit, hub-kit alignment, and the common-framework proposal ([86540c2](https://github.com/bamr87/lifehacker.dev/commit/86540c27694b3c9217376ebae93a276a12689237))
* **brand:** satire-first recalibration — 9-word hype list, persona bylines, tier-2 economy ([#320](https://github.com/bamr87/lifehacker.dev/issues/320)) ([7cdf761](https://github.com/bamr87/lifehacker.dev/commit/7cdf76149cdf2713f2e848e2e4a9bc25322bbb2e))
* **ci:** add MCP-compatible script entrypoints (plan JSON, results-dir, frontmatter scoping) ([#392](https://github.com/bamr87/lifehacker.dev/issues/392)) ([d107569](https://github.com/bamr87/lifehacker.dev/commit/d10756931f4216cb545e23cc6be475362512ed82))
* **concepts:** the durable concept layer, queryable through the MCP ([#301](https://github.com/bamr87/lifehacker.dev/issues/301)) ([bd7488a](https://github.com/bamr87/lifehacker.dev/commit/bd7488a66328ae0be5f9d9e9ffc059f4dcc06f6c))
* **config:** favicon setup + revive docs sidebar ([#381](https://github.com/bamr87/lifehacker.dev/issues/381)) ([b0e36d3](https://github.com/bamr87/lifehacker.dev/commit/b0e36d393fb8aba7555cccc6f0c8114b8338952b))
* consume the preview-image engine as the zer0-image-generator gem ([021e00a](https://github.com/bamr87/lifehacker.dev/commit/021e00a4163d1e06c4680462f686a0491867998e))
* **content:** doc — the skeleton key in the robot's pocket (DOC-024) ([#367](https://github.com/bamr87/lifehacker.dev/issues/367)) ([aab3b5d](https://github.com/bamr87/lifehacker.dev/commit/aab3b5d82c6d918a39ce691e3ad4b512bb1bc492))
* **content:** field note — threat-model the unpinned remote_theme supply chain ([#366](https://github.com/bamr87/lifehacker.dev/issues/366)) ([ed345cc](https://github.com/bamr87/lifehacker.dev/commit/ed345cc144d74699b6d4fe077a9dcefc4d2368d7))
* **field-notes:** the date gate accepts 'sat', 'May', and Feb 30 ([#492](https://github.com/bamr87/lifehacker.dev/issues/492)) ([e5bc561](https://github.com/bamr87/lifehacker.dev/commit/e5bc5613f86784b2648216ecf8b637edde07b1a3))
* **field-notes:** threat-model the backlog merge driver (Cass, POST-037) ([#485](https://github.com/bamr87/lifehacker.dev/issues/485)) ([8691f59](https://github.com/bamr87/lifehacker.dev/commit/8691f59b894656cd4193291d31e1c2df51620af5))
* **field-notes:** threat-model the harness parsing fork PRs with unsafe_load ([#500](https://github.com/bamr87/lifehacker.dev/issues/500)) ([99fe074](https://github.com/bamr87/lifehacker.dev/commit/99fe074bac66d8da9c44b6388bd23596a2b37f6f))
* **fleet:** rotate AI authors per section + wire preview art into publication ([#350](https://github.com/bamr87/lifehacker.dev/issues/350)) ([0f2bd93](https://github.com/bamr87/lifehacker.dev/commit/0f2bd934ad569cb2da8dfefa7250509eaf69c3c5))
* **fleet:** weekly Top Story epic — fable persona, computed figures, OpenAI image option ([#462](https://github.com/bamr87/lifehacker.dev/issues/462)) ([1a200e9](https://github.com/bamr87/lifehacker.dev/commit/1a200e96aadc85f87859cc6f6f3807c97411f5c9))
* **hacks:** $GITHUB_STEP_SUMMARY — stop scrolling CI logs (SRC-011) ([#348](https://github.com/bamr87/lifehacker.dev/issues/348)) ([e36c87f](https://github.com/bamr87/lifehacker.dev/commit/e36c87f410173c66373ef39f0b73043082c56e96))
* **hacks:** coverage gate on branches, not just lines (SRC-010) ([#341](https://github.com/bamr87/lifehacker.dev/issues/341)) ([0e7729f](https://github.com/bamr87/lifehacker.dev/commit/0e7729f8dad77e99c492f001009b9dba8a110a2f))
* **hacks:** fix tofu boxes with a Nerd Font, verified the honest way ([#484](https://github.com/bamr87/lifehacker.dev/issues/484)) ([18807cb](https://github.com/bamr87/lifehacker.dev/commit/18807cb4e5571fa06f40e545c561bb0759b18409))
* **hacks:** idempotent data loads — the upsert & watermark that survive a retry (SRC-023) ([#451](https://github.com/bamr87/lifehacker.dev/issues/451)) ([db5637b](https://github.com/bamr87/lifehacker.dev/commit/db5637b11d24c710730eebacc1e71b4b5329f0d9))
* **hack:** size your connection pool by cores, not hope (SRC-013) ([#373](https://github.com/bamr87/lifehacker.dev/issues/373)) ([66d6904](https://github.com/bamr87/lifehacker.dev/commit/66d69040f21e3d95b699d0704a39b6ee35b812c4))
* **hacks:** kill the Django N+1 with select_related and prefetch_related ([#499](https://github.com/bamr87/lifehacker.dev/issues/499)) ([0ca9b58](https://github.com/bamr87/lifehacker.dev/commit/0ca9b58997cf8207a6df359aede2347d28561be9))
* **hacks:** sign your commits with GPG for the Verified badge (SRC-029) ([#491](https://github.com/bamr87/lifehacker.dev/issues/491)) ([4411dbf](https://github.com/bamr87/lifehacker.dev/commit/4411dbf7c6df51b41df2e81d2917b249cbb384b8))
* **hacks:** you can't gate a workflow step on a secret in if: — promote it to an env first ([#365](https://github.com/bamr87/lifehacker.dev/issues/365)) ([9fe8a9a](https://github.com/bamr87/lifehacker.dev/commit/9fe8a9ac8845f252fc19c31d6625506049719f45))
* **mcp:** scaffold the P0 lifehacker-read MCP server ([#281](https://github.com/bamr87/lifehacker.dev/issues/281)) ([24dd84b](https://github.com/bamr87/lifehacker.dev/commit/24dd84b801c631bcf4c1e9cd125ff16bbe0a6b27))
* **post:** field note on the comment guard upstream changed 3 days after we documented it ([#342](https://github.com/bamr87/lifehacker.dev/issues/342)) ([4dd6dac](https://github.com/bamr87/lifehacker.dev/commit/4dd6dac755651d35e228c0a7460d11daaad12d03))
* **preview:** generate the six section fallback banners ([#632](https://github.com/bamr87/lifehacker.dev/issues/632)) ([4545a15](https://github.com/bamr87/lifehacker.dev/commit/4545a15fbc5447773b0258080dfa39e14b57bd00))
* **preview:** illustrate banners with Claude-authored motifs ([#515](https://github.com/bamr87/lifehacker.dev/issues/515)) ([0715766](https://github.com/bamr87/lifehacker.dev/commit/071576616f519e36e07ebaf95646bf984422eff3))
* **preview:** opt-in xAI Imagine covers via OAuth ([#527](https://github.com/bamr87/lifehacker.dev/issues/527)) ([b4b4cbf](https://github.com/bamr87/lifehacker.dev/commit/b4b4cbfd07c796ff3c15109018ca1af4b448e7c8))
* **preview:** replace the template banner pipeline with Trace Bloom generative art ([#422](https://github.com/bamr87/lifehacker.dev/issues/422)) ([b2dc63a](https://github.com/bamr87/lifehacker.dev/commit/b2dc63a63c747456b90dfca4f571292688fc1fb8))
* **previews:** AI art for 16 tools articles + restore per-section styles ([#368](https://github.com/bamr87/lifehacker.dev/issues/368)) ([4fd2349](https://github.com/bamr87/lifehacker.dev/commit/4fd2349b9b1762a031001d852693bc2b755515a3))
* **previews:** AI art for the remaining 85 articles ([#369](https://github.com/bamr87/lifehacker.dev/issues/369)) ([1b22f7a](https://github.com/bamr87/lifehacker.dev/commit/1b22f7a9d52a039dd6ae537bbf7b998a581f49c6))
* **previews:** AI banners for every post (80 new, full coverage) ([bc8ed88](https://github.com/bamr87/lifehacker.dev/commit/bc8ed886196ce0366432b3a76f02e7c4d610975e))
* **previews:** homepage AI banners + per-collection visual identities ([dd4b70e](https://github.com/bamr87/lifehacker.dev/commit/dd4b70e525074f145992ba05e38b8d11d0458341))
* **previews:** resolve the provider capability ladder + Claude-authored SVG banners ([#401](https://github.com/bamr87/lifehacker.dev/issues/401)) ([46a01c9](https://github.com/bamr87/lifehacker.dev/commit/46a01c927d2e837d4137d24714be42a40ab4908e))
* **previews:** retro-pixel tools + friendly-robot field notes ([483289f](https://github.com/bamr87/lifehacker.dev/commit/483289fa61c153b805a5bb051800d29704e62231))
* **previews:** shared section banners + provider capability ladder (−257 MB) ([#400](https://github.com/bamr87/lifehacker.dev/issues/400)) ([b553ef1](https://github.com/bamr87/lifehacker.dev/commit/b553ef1cfb414f765f344b8ea804be0b0c0a2ea1))
* **previews:** SVG-only, content-aware preview banners ([#398](https://github.com/bamr87/lifehacker.dev/issues/398)) ([7c8f943](https://github.com/bamr87/lifehacker.dev/commit/7c8f943a276a743df2a5cfa0dbf4953a875697f5))
* **scout:** content-scout — crawl it-journey.dev for on-brand backlog ideas ([#196](https://github.com/bamr87/lifehacker.dev/issues/196)) ([b4d7d1c](https://github.com/bamr87/lifehacker.dev/commit/b4d7d1cd24e53221b33adc0462d10bddf5d0f0c6))
* the plugin that isn't a plugin — AI preview-image generator (zer0-mistakes[#296](https://github.com/bamr87/lifehacker.dev/issues/296)) ([#298](https://github.com/bamr87/lifehacker.dev/issues/298)) ([8d8062b](https://github.com/bamr87/lifehacker.dev/commit/8d8062b36225607c87caa7af94a13884141f62fd))
* **tools:** add the honest grep review ([#336](https://github.com/bamr87/lifehacker.dev/issues/336)) ([985f861](https://github.com/bamr87/lifehacker.dev/commit/985f861bbbc166fa2bb1f9dc1ec7387b7171443e))
* **triage:** close the loop — sweep stale bot issues, stop redundant factory analyses ([#382](https://github.com/bamr87/lifehacker.dev/issues/382)) ([8e49ceb](https://github.com/bamr87/lifehacker.dev/commit/8e49cebd0d4ffbf292fbe6503513983577878a3e))
* **wire:** benchmark theater field guide — how to read a launch chart (Rhea, WIRE-002) ([#488](https://github.com/bamr87/lifehacker.dev/issues/488)) ([38a5d8c](https://github.com/bamr87/lifehacker.dev/commit/38a5d8c34fce1bac5d79c44960fb4e3ce0938a75))
* **wire:** Claude text watermark dispatch (WIRE-003) ([#494](https://github.com/bamr87/lifehacker.dev/issues/494)) ([4193248](https://github.com/bamr87/lifehacker.dev/commit/41932484d3f2bf041cdb11f86b7b576d2a451e9c))
* **wire:** OpenAI agent breached Hugging Face to cheat a benchmark (WIRE-004) ([#502](https://github.com/bamr87/lifehacker.dev/issues/502)) ([5d8e937](https://github.com/bamr87/lifehacker.dev/commit/5d8e9377315dc29c25cbdd5814814cedd3839554))
* **wire:** the newsroom — press charter, The Wire, Rhea Porter, and the wire-scout loop ([#471](https://github.com/bamr87/lifehacker.dev/issues/471)) ([ee65b3a](https://github.com/bamr87/lifehacker.dev/commit/ee65b3a5dd4f759f228fdfbc101607c46c1779d7))
* **wire:** the slop economy dispatch on AI writing at scale ([#495](https://github.com/bamr87/lifehacker.dev/issues/495)) ([1ab7f8a](https://github.com/bamr87/lifehacker.dev/commit/1ab7f8aa14cddab7d073369f6acfa89f9ea3bbf0))


### Fixed

* **ai:** hash usage-record ids with SHA-256 (CodeQL rb/weak-sensitive-data-hashing) ([6d152ab](https://github.com/bamr87/lifehacker.dev/commit/6d152abfb7541fd3f8bb906c385a1d5b4070b426))
* **backlog:** dedupe DOC-024/POST-025 id collisions from a union merge ([#391](https://github.com/bamr87/lifehacker.dev/issues/391)) ([d9afb09](https://github.com/bamr87/lifehacker.dev/commit/d9afb0928c54da462db9e056fe3530c880149345))
* **backlog:** renumber the two ids that collided in the [#565](https://github.com/bamr87/lifehacker.dev/issues/565) union-merge ([40fbe20](https://github.com/bamr87/lifehacker.dev/commit/40fbe20cf00d152bc5f30a6496ba4a77c1c5706a))
* **backlog:** renumber the two ids that collided in the [#565](https://github.com/bamr87/lifehacker.dev/issues/565) union-merge ([be390e3](https://github.com/bamr87/lifehacker.dev/commit/be390e3842159f92efe7700844413a8224d12d3b))
* **backlog:** renumber the two ids that collided in the [#565](https://github.com/bamr87/lifehacker.dev/issues/565) union-merge ([fefc1e1](https://github.com/bamr87/lifehacker.dev/commit/fefc1e1cb94d68543941424a2382b7ac83e311c3))
* **backlog:** resolve four duplicate ids that reddened the content gate ([#195](https://github.com/bamr87/lifehacker.dev/issues/195)) ([fb93a22](https://github.com/bamr87/lifehacker.dev/commit/fb93a22873805cd68a7b0772e64045cf0152d26a))
* **brand:** accept scare-quoted "10x" in tmux + word-police (WO [#163](https://github.com/bamr87/lifehacker.dev/issues/163)) ([#175](https://github.com/bamr87/lifehacker.dev/issues/175)) ([b905e36](https://github.com/bamr87/lifehacker.dev/commit/b905e368cf8f2f2147b393ee2f259307038b4865)), closes [#107](https://github.com/bamr87/lifehacker.dev/issues/107) [#117](https://github.com/bamr87/lifehacker.dev/issues/117) [#118](https://github.com/bamr87/lifehacker.dev/issues/118) [#119](https://github.com/bamr87/lifehacker.dev/issues/119)
* **brand:** accept-ledger 'just' in 3 later-2024 posts (work order [#171](https://github.com/bamr87/lifehacker.dev/issues/171)) ([#303](https://github.com/bamr87/lifehacker.dev/issues/303)) ([471d671](https://github.com/bamr87/lifehacker.dev/commit/471d671196a3587936fd00542a9c5b2998abbc5c))
* **brand:** accept-ledger 8 legitimate "just" uses across four 2025 posts ([#311](https://github.com/bamr87/lifehacker.dev/issues/311)) ([067f38b](https://github.com/bamr87/lifehacker.dev/commit/067f38b760af86304c1508cf1ebd4fee922a35ef)), closes [#148](https://github.com/bamr87/lifehacker.dev/issues/148) [#149](https://github.com/bamr87/lifehacker.dev/issues/149) [#150](https://github.com/bamr87/lifehacker.dev/issues/150) [#151](https://github.com/bamr87/lifehacker.dev/issues/151) [#172](https://github.com/bamr87/lifehacker.dev/issues/172)
* **brand:** accept-ledger hype words in labeled satire/fiction (work order [#164](https://github.com/bamr87/lifehacker.dev/issues/164)) ([#177](https://github.com/bamr87/lifehacker.dev/issues/177)) ([85a9d89](https://github.com/bamr87/lifehacker.dev/commit/85a9d890cafc532925923ad850b503474803d82d)), closes [#138](https://github.com/bamr87/lifehacker.dev/issues/138) [#139](https://github.com/bamr87/lifehacker.dev/issues/139) [#140](https://github.com/bamr87/lifehacker.dev/issues/140) [#146](https://github.com/bamr87/lifehacker.dev/issues/146)
* **brand:** accept-ledger legitimate 'just' uses in docs collection (WO [#167](https://github.com/bamr87/lifehacker.dev/issues/167)) ([#222](https://github.com/bamr87/lifehacker.dev/issues/222)) ([8257fbd](https://github.com/bamr87/lifehacker.dev/commit/8257fbdad1d5882c9f56bbe5e2b861a2bd9267fc)), closes [#104](https://github.com/bamr87/lifehacker.dev/issues/104) [#105](https://github.com/bamr87/lifehacker.dev/issues/105) [#106](https://github.com/bamr87/lifehacker.dev/issues/106)
* **brand:** accept-ledger the legitimate 'just' uses in docs + hacks (WO [#166](https://github.com/bamr87/lifehacker.dev/issues/166)) ([#202](https://github.com/bamr87/lifehacker.dev/issues/202)) ([a08ac13](https://github.com/bamr87/lifehacker.dev/commit/a08ac13442aecef5c43b8299ff9906bf0c52cb69))
* **brand:** adjudicate 2021–2023 _posts 'just' brand-lint batch (WO [#169](https://github.com/bamr87/lifehacker.dev/issues/169)) ([#257](https://github.com/bamr87/lifehacker.dev/issues/257)) ([4f1a542](https://github.com/bamr87/lifehacker.dev/commit/4f1a5424a44e94bbb7953f231b83305fa741b567))
* **brand:** resolve `just` lint + SEO description across three hacks (work order [#165](https://github.com/bamr87/lifehacker.dev/issues/165)) ([#194](https://github.com/bamr87/lifehacker.dev/issues/194)) ([fcec234](https://github.com/bamr87/lifehacker.dev/commit/fcec23481e8fcc8d46cce017e70a8d3d1e56f659))
* **brand:** reword sincere 'just' in 2019 Django/Lambda posts (WO [#168](https://github.com/bamr87/lifehacker.dev/issues/168)) ([#239](https://github.com/bamr87/lifehacker.dev/issues/239)) ([795d0bc](https://github.com/bamr87/lifehacker.dev/commit/795d0bc1dae5ca8cb6f62703431b92e9aff01d1b)), closes [#120](https://github.com/bamr87/lifehacker.dev/issues/120) [#121](https://github.com/bamr87/lifehacker.dev/issues/121)
* **ci:** auto-update gate tests FLEET_TOKEN validity, not just presence ([#486](https://github.com/bamr87/lifehacker.dev/issues/486)) ([bf3d372](https://github.com/bamr87/lifehacker.dev/commit/bf3d3729f0db05c1cf834adfa16c072af5cf4710))
* **ci:** build every check against the theme's current commit ([#684](https://github.com/bamr87/lifehacker.dev/issues/684)) ([3c2db71](https://github.com/bamr87/lifehacker.dev/commit/3c2db716bb28eb220c9e3c4d58c9b161e41ef4e3))
* **ci:** derive the sub-topic anchor ignore from published tags ([#510](https://github.com/bamr87/lifehacker.dev/issues/510)) ([ae08ac8](https://github.com/bamr87/lifehacker.dev/commit/ae08ac8f8785f7bde7029edf2451f4aedaa1b045))
* **ci:** enforce the rhea byline on Wire dispatches ([5fc6a3f](https://github.com/bamr87/lifehacker.dev/commit/5fc6a3f6664967bbbcc1d7504f9b76e3ffcf1298))
* **ci:** enforce the rhea byline on Wire dispatches ([3891988](https://github.com/bamr87/lifehacker.dev/commit/38919885e5f39885727f84b41736ac538e6292c0))
* **ci:** key claude.yml concurrency on the ref, not the run id ([#443](https://github.com/bamr87/lifehacker.dev/issues/443)) ([f5de362](https://github.com/bamr87/lifehacker.dev/commit/f5de3626610e489ac12651eaf400cc946ea8062b))
* **ci:** make a rejected AI call fail loudly instead of no-opping green ([#517](https://github.com/bamr87/lifehacker.dev/issues/517)) ([0841569](https://github.com/bamr87/lifehacker.dev/commit/0841569358e17558bdbeb660f518f3f30e2110b4))
* **ci:** probe FLEET_TOKEN before content-review's checkout ([#677](https://github.com/bamr87/lifehacker.dev/issues/677)) ([9367a73](https://github.com/bamr87/lifehacker.dev/commit/9367a73fd1179c878f44916bfdd1ec32fa668a9e))
* **ci:** probe FLEET_TOKEN in triage instead of trusting the || fallback ([#547](https://github.com/bamr87/lifehacker.dev/issues/547)) ([effb98b](https://github.com/bamr87/lifehacker.dev/commit/effb98bcf8f7faf3de71d5ff58292ead15886f4f))
* **ci:** probe FLEET_TOKEN instead of trusting that it is set ([#498](https://github.com/bamr87/lifehacker.dev/issues/498)) ([0c737db](https://github.com/bamr87/lifehacker.dev/commit/0c737dbd0d46769e6eedc0588dd90e4d8b851452))
* **ci:** repair the union-merge key split and close the gaps that hid it ([#441](https://github.com/bamr87/lifehacker.dev/issues/441)) ([5322e8b](https://github.com/bamr87/lifehacker.dev/commit/5322e8b39c7eb81e45bc21d5c72b3bfbe5c6b6c2))
* **ci:** stop auto-update pushing spliced backlog merges ([#468](https://github.com/bamr87/lifehacker.dev/issues/468)) ([fb87f6e](https://github.com/bamr87/lifehacker.dev/commit/fb87f6e63e0f0b5bee26839147048202cfc115fd))
* **ci:** stop resolve-gh-token's doc strings from failing the manifest ([#520](https://github.com/bamr87/lifehacker.dev/issues/520)) ([87a34e2](https://github.com/bamr87/lifehacker.dev/commit/87a34e2f34da9aaca6e538033d10a6ae0dabf084))
* **ci:** strip the theme's examples/ from the overlay build ([#428](https://github.com/bamr87/lifehacker.dev/issues/428)) ([85a9a4f](https://github.com/bamr87/lifehacker.dev/commit/85a9a4f3dc6b4b8443d11953e589042863ccb356))
* **ci:** strip theme features/ from the overlay build ([#709](https://github.com/bamr87/lifehacker.dev/issues/709)) ([d1c2ca1](https://github.com/bamr87/lifehacker.dev/commit/d1c2ca1a1fec99f4354053ec8d94f52e8bbd9b39))
* **ci:** wire every check to the findings contract, and add the oneline check ([#442](https://github.com/bamr87/lifehacker.dev/issues/442)) ([3576eb2](https://github.com/bamr87/lifehacker.dev/commit/3576eb219e225f82a07cbcb95216518e0c6c9181))
* **content:** add Trace Bloom preview banner to the Grok Bot review ([#680](https://github.com/bamr87/lifehacker.dev/issues/680)) ([#705](https://github.com/bamr87/lifehacker.dev/issues/705)) ([8464282](https://github.com/bamr87/lifehacker.dev/commit/84642825ba678f1b716d649d16311f46499c78ca))
* **content:** raw-guard template braces in code samples + missing section banners ([#478](https://github.com/bamr87/lifehacker.dev/issues/478)) ([bf7b9a6](https://github.com/bamr87/lifehacker.dev/commit/bf7b9a6fb7600d3cc859d6912376bb67e5dce881))
* **content:** trim SEO description under 160 chars for the-build-that-deletes-its-own-plugins ([#330](https://github.com/bamr87/lifehacker.dev/issues/330)) ([3e3e7fa](https://github.com/bamr87/lifehacker.dev/commit/3e3e7fac73769c729250ba983412346d2d40f017)), closes [#224](https://github.com/bamr87/lifehacker.dev/issues/224) [#223](https://github.com/bamr87/lifehacker.dev/issues/223) [#252](https://github.com/bamr87/lifehacker.dev/issues/252)
* **content:** trim SEO description under 160 chars on skip-guard post ([#481](https://github.com/bamr87/lifehacker.dev/issues/481)) ([a8b35be](https://github.com/bamr87/lifehacker.dev/commit/a8b35be1de63d8bd1ac93162976e77d6245ae48b)), closes [#472](https://github.com/bamr87/lifehacker.dev/issues/472) [#480](https://github.com/bamr87/lifehacker.dev/issues/480)
* **data:** de-duplicate the published key in backlog.yml (DOC-025 / POST-026) ([#406](https://github.com/bamr87/lifehacker.dev/issues/406)) ([96c879e](https://github.com/bamr87/lifehacker.dev/commit/96c879edf989040ad2ce3ee1ddc8fedc7186ef01))
* **deps:** bump json 2.21.1 -&gt; 2.21.2 (security) ([#707](https://github.com/bamr87/lifehacker.dev/issues/707)) ([7bad5bd](https://github.com/bamr87/lifehacker.dev/commit/7bad5bd0f7e2a960f81359529cea43ddf4a74302))
* **docs:** reflow constitution to one paragraph per line; settle loop ledger ([#743](https://github.com/bamr87/lifehacker.dev/issues/743)) ([9644def](https://github.com/bamr87/lifehacker.dev/commit/9644def076e03f59fe42ecd03b54a6306b22d1b5))
* **factory:** fixer turn budget 40 → 100 + turn-discipline prompt guidance ([#174](https://github.com/bamr87/lifehacker.dev/issues/174)) ([c372810](https://github.com/bamr87/lifehacker.dev/commit/c3728104b340a735e5f56b79d175bfe1d96a29bd))
* **feed:** lift the 10-post RSS cap; docs: fill the CLAUDE.md template ([#403](https://github.com/bamr87/lifehacker.dev/issues/403)) ([dfb9c9b](https://github.com/bamr87/lifehacker.dev/commit/dfb9c9b24a475b7cab7772263b9ac89e22c412ef))
* **field-note:** trim over-limit SEO description on zero-posts-picker post ([#634](https://github.com/bamr87/lifehacker.dev/issues/634)) ([631679f](https://github.com/bamr87/lifehacker.dev/commit/631679fc3a7307cbcaa9ba44268b6c13fc60620c)), closes [#624](https://github.com/bamr87/lifehacker.dev/issues/624)
* **loop:** target sub-cap SEO description in generator templates ([#698](https://github.com/bamr87/lifehacker.dev/issues/698)) ([21df036](https://github.com/bamr87/lifehacker.dev/commit/21df0367c81ce6dfc635be3bcf8b955f0f879221))
* **news:** finish the [#338](https://github.com/bamr87/lifehacker.dev/issues/338) migration — strand hack + theme-nav dead anchors ([#351](https://github.com/bamr87/lifehacker.dev/issues/351)) ([1d0da28](https://github.com/bamr87/lifehacker.dev/commit/1d0da28df04bfe6a6ae31bc4cfa66cda27396f7e))
* **preview:** add missing section-hacks.svg fallback banner ([#456](https://github.com/bamr87/lifehacker.dev/issues/456)) ([4104e15](https://github.com/bamr87/lifehacker.dev/commit/4104e1556f6f5b3c1a7d0616570ddcab0b23528e)), closes [#446](https://github.com/bamr87/lifehacker.dev/issues/446) [#447](https://github.com/bamr87/lifehacker.dev/issues/447) [#454](https://github.com/bamr87/lifehacker.dev/issues/454)
* **release:** skip release-please when it has no credential to open the PR ([95bad08](https://github.com/bamr87/lifehacker.dev/commit/95bad08b0f2e8f296e534fe56a7f4f9081bf7baf))
* **release:** skip release-please when it has no credential to open the PR ([dc7d37d](https://github.com/bamr87/lifehacker.dev/commit/dc7d37d56694bc270ae9fd2c4ce11261d1b59a4e))


### Documentation

* a plan to let other robots read the robot (MCP integration) ([#278](https://github.com/bamr87/lifehacker.dev/issues/278)) ([0ba0a27](https://github.com/bamr87/lifehacker.dev/commit/0ba0a27a04e306dbe5b0d226565591759f1ae827))
* add feature catalog, constitution and amendments; link PRD ([#732](https://github.com/bamr87/lifehacker.dev/issues/732)) ([46bddd9](https://github.com/bamr87/lifehacker.dev/commit/46bddd9c7f45ea20fbc3a52e62592e1c78bf8327))
* add PRD.md ([#731](https://github.com/bamr87/lifehacker.dev/issues/731)) ([ce75dc4](https://github.com/bamr87/lifehacker.dev/commit/ce75dc46207d73dc9581202663262053e158799d))
* **agents:** de-drift the devops-manager sim count references ([#573](https://github.com/bamr87/lifehacker.dev/issues/573)) ([5a84a38](https://github.com/bamr87/lifehacker.dev/commit/5a84a38c823cd5ea8f75d8513cfafa63290332f0))
* **autopilot:** the fleet's operator link — GitFactory's Fleet Command for this repo + irony-works ([0436398](https://github.com/bamr87/lifehacker.dev/commit/043639888f6c6ec6b959c8563d7c48538597cf56))
* **autopilot:** the fleet's operator link (GitFactory Fleet Command) ([f6dd70a](https://github.com/bamr87/lifehacker.dev/commit/f6dd70a98a3a52c84b0f0656d1de1d32e312f703))
* **changelog:** add CHANGELOG.md in Keep a Changelog format ([#713](https://github.com/bamr87/lifehacker.dev/issues/713)) ([2dcb4fb](https://github.com/bamr87/lifehacker.dev/commit/2dcb4fbaf3296e24210cd0e9445db0912655fef4))
* **claude:** document theme-scout, real commit types, and the floating theme pin ([#508](https://github.com/bamr87/lifehacker.dev/issues/508)) ([3ea1f25](https://github.com/bamr87/lifehacker.dev/commit/3ea1f2599fb297e309c44431d4a87fbb3efcf678))
* **claude:** name the .claude entry-point skills + quarantine guardrails ([#421](https://github.com/bamr87/lifehacker.dev/issues/421)) ([64fb3f7](https://github.com/bamr87/lifehacker.dev/commit/64fb3f73874773d9e68030578de958b636c7dece))
* harmonize documentation to the fleet docs framework ([#733](https://github.com/bamr87/lifehacker.dev/issues/733)) ([b925c6b](https://github.com/bamr87/lifehacker.dev/commit/b925c6ba65f5e0b6c7f978e0190453a022e72235))
* **meta:** a prompt without its input is half a receipt (SRC-088, cass) ([#501](https://github.com/bamr87/lifehacker.dev/issues/501)) ([637ff81](https://github.com/bamr87/lifehacker.dev/commit/637ff810aaedf147c9c97769883d7bb95d6e8f4a))
* **meta:** the check that proofreads the newsroom but won't vet its sources ([#487](https://github.com/bamr87/lifehacker.dev/issues/487)) ([03e85d2](https://github.com/bamr87/lifehacker.dev/commit/03e85d2ec236631e3511f1069e96175bffc70939))
* **meta:** the gate that only reads your own diff ([#343](https://github.com/bamr87/lifehacker.dev/issues/343)) ([3fbe8c4](https://github.com/bamr87/lifehacker.dev/commit/3fbe8c4e0c2d0ee55b3cbd719314bc65f7781e0a))
* **meta:** the scoreboard that reads an empty stadium as a win ([#493](https://github.com/bamr87/lifehacker.dev/issues/493)) ([b212d6a](https://github.com/bamr87/lifehacker.dev/commit/b212d6a292fd34be0d973612f5157fc69ac3e6b0))
* **meta:** threat-model the quarantine guardrail (Cass Vector) ([#461](https://github.com/bamr87/lifehacker.dev/issues/461)) ([5c65688](https://github.com/bamr87/lifehacker.dev/commit/5c65688fd1750b7f5c745548d8a88e4fe0182cba))
* **proposals:** correct three round-1 rows to the repos' current state ([7ae74d6](https://github.com/bamr87/lifehacker.dev/commit/7ae74d661fa207ccd86eaf3f51a9649c4efb8bea))
* **proposals:** the common framework for content sites and AI harnesses ([fc6c738](https://github.com/bamr87/lifehacker.dev/commit/fc6c7381b2894bf27a8a6ccdf06bca0946eeac79))
* **readme:** align README with the portfolio standard ([#712](https://github.com/bamr87/lifehacker.dev/issues/712)) ([9b8d08a](https://github.com/bamr87/lifehacker.dev/commit/9b8d08a7054147091d72de70c01fed3ba3f1640e))
* seal the evidence before the robot wakes up (SRC-020) ([#277](https://github.com/bamr87/lifehacker.dev/issues/277)) ([762f651](https://github.com/bamr87/lifehacker.dev/commit/762f65144d3ec4d7c0b3c19af67386839d6b32d2))

## Changelog

All notable changes to this project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- `CHANGELOG.md`, in Keep a Changelog format.

## History

No versions have been tagged yet. The project started on 2026-06-22 and has 569 commits on `main`. The most recent changes:

- 2026-10-17: docs(readme): align README with the portfolio standard ([#712](https://github.com/bamr87/lifehacker.dev/pull/712))
- 2026-10-17: triage: refresh queue + health dashboard ([#711](https://github.com/bamr87/lifehacker.dev/pull/711)) (×64)
- 2026-10-17: fix(ci): strip theme features/ from the overlay build ([#709](https://github.com/bamr87/lifehacker.dev/pull/709))
- 2026-10-17: fix(content): add Trace Bloom preview banner to the Grok Bot review (#680) ([#705](https://github.com/bamr87/lifehacker.dev/pull/705))
- 2026-10-17: ci(auto-merge): never merge draft PRs ([#703](https://github.com/bamr87/lifehacker.dev/pull/703))
- 2026-10-16: fix(deps): bump json 2.21.1 -&gt; 2.21.2 (security) ([#707](https://github.com/bamr87/lifehacker.dev/pull/707))
- 2026-10-15: content(field-note): my robots were failing on a schedule, and the schedule was the bug ([#706](https://github.com/bamr87/lifehacker.dev/pull/706))
- 2026-10-14: ci: pin standard-ci to @v2 (needs the v2 tag) ([#702](https://github.com/bamr87/lifehacker.dev/pull/702))
- 2026-10-14: ci: cut wasted scheduled runs and stagger AI crons (Actions waste reduction) ([#701](https://github.com/bamr87/lifehacker.dev/pull/701))
- 2026-10-12: fix(loop): target sub-cap SEO description in generator templates ([#698](https://github.com/bamr87/lifehacker.dev/pull/698))
- 2026-10-07: build(deps): bump ip-address in /mcp/lifehacker-read ([#675](https://github.com/bamr87/lifehacker.dev/pull/675)) (×2)
- 2026-10-06: build(deps): bump @modelcontextprotocol/sdk in /mcp/lifehacker-read ([#692](https://github.com/bamr87/lifehacker.dev/pull/692))
- …and 406 earlier changes.

The full record is in the [commit history](https://github.com/bamr87/lifehacker.dev/commits/main) and the [merged pull requests](https://github.com/bamr87/lifehacker.dev/pulls?q=is%3Apr+is%3Amerged).
