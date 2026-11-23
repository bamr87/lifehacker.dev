---
layout: default
title: "Tags"
description: "Browse lifehacker.dev by tag."
permalink: /tags/
sitemap: false
sidebar:
  nav: main
---

# Tags

Hand-authored (the archive plugin doesn't run on GitHub Pages). Every hack, tool review, and field note is a post now, so a single pass over `site.posts` pools every `#tag` the theme links to — and it resolves here. An [agency](/agencies/) tags its pages too: its tags get their heading here, with a link to the agency and a count rather than a list of every page it filed.

{% assign all_docs = site.posts %}
{% comment %}The published agency collections (_data/agencies.yml `published:`), so a tag badge on an agency page resolves here as a post's does.{% endcomment %}
{% capture agencyblob %}{% for agency in site.data.agencies.agencies %}{% for s in agency.sites %}{% if s.published %}{% assign coll = site.collections | where: "label", s.published.collection | first %}{% for d in coll.docs %}{% for t in d.tags %}{{ t }},{% endfor %}{% endfor %}{% endif %}{% endfor %}{% endfor %}{% endcapture %}
{% capture tagblob %}{% for d in all_docs %}{% for t in d.tags %}{{ t }},{% endfor %}{% endfor %}{{ agencyblob }}{% endcapture %}
{% assign all_tags = tagblob | split: "," | uniq | sort %}
{% for tag in all_tags %}{% unless tag == "" %}
<h2 id="{{ tag | slugify }}">{{ tag }}</h2>
<ul>
{% for d in all_docs %}{% if d.tags contains tag %}<li><a href="{{ d.url | relative_url }}">{{ d.title }}</a></li>{% endif %}{% endfor %}
{% for agency in site.data.agencies.agencies %}{% for s in agency.sites %}{% if s.published %}{% assign coll = site.collections | where: "label", s.published.collection | first %}{% assign filed = coll.docs | where_exp: "d", "d.tags contains tag" %}{% if filed.size > 0 %}<li><a href="{{ s.published.url | relative_url }}">{{ agency.name }}</a> <span class="text-body-secondary small">— {{ filed.size }} pages</span></li>{% endif %}{% endif %}{% endfor %}{% endfor %}
</ul>
{% endunless %}{% endfor %}
{% unless all_tags.size > 0 %}<p class="text-body-secondary">No tags yet.</p>{% endunless %}
