---
layout: default
title: "Git With the Program"
description: "Repository history with receipts: real commits, useful lessons, and engineering theater reported with a straight face."
permalink: /series/git-with-the-program/
sidebar: false
---

# Git With the Program

The commit log has been called to testify. This [Field Notes]({{ '/news/field-notes/' | relative_url }}) series follows real repository history through the part where it broke, the change that followed, and what the evidence actually supports. The detective theater is the joke. The commits are not.

Each article cites its sources, labels inference, and admits the limits of its evidence. A test file is not a passing test run; a confident commit message is not a sworn affidavit. Drafts stay off this page until human review clears them for publication.

{% assign articles = site.posts | where: 'series', 'git-with-the-program' | where_exp: 'post', 'post.published != false' | sort: 'date' | reverse %}
{% if articles.size > 0 %}
<ul>
{% for post in articles %}
  <li><a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a> <time datetime="{{ post.date | date: '%Y-%m-%d' }}">{{ post.date | date: '%Y-%m-%d' }}</time></li>
{% endfor %}
</ul>
{% else %}
No published installments yet. The evidence is still being cross-examined.
{% endif %}
