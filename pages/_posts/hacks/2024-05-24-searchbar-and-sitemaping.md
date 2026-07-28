---
title: "A searchable, sortable Jekyll sitemap from your collections with no plugins"
description: "Build one HTML page that lists every doc across your Jekyll collections, with a live search box and click-to-sort columns — no plugins, no JS framework."
date: 2024-05-24
categories: [Hacks]
tags: [jekyll, web-dev]
author: amr
excerpt: "One Liquid loop plus forty lines of vanilla JS turns your collections into a filterable, sortable index page."
preview: /images/previews/section-hacks.svg
permalink: /hacks/searchbar-and-sitemaping/
---
You have a Jekyll site with four collections and ninety-odd files in them. You want one page where you can type "ssh" and watch the list shrink to the three things about ssh, then click a column header to sort by date. The productivity move here is to install three plugins and a search index and a 200KB JavaScript library.

You don't need any of that. You need one Liquid loop and about forty lines of vanilla JS that you paste into a page and never think about again. It runs entirely in the browser, ships as static HTML, and works on GitHub Pages without a single plugin in the allowlist.

Here's the whole thing, including the two places it will lie to you if you copy it from a Stack Overflow answer (it sorted dates alphabetically and the first click sorted backwards — both real, both below).

## Step 1: Render every collection into one table

Jekyll exposes `site.collections`, and each collection has a `.docs` array. Loop the collections, loop the docs, emit a row. One table, every page on the site.

Drop this in a page — call it `sitemap.md` or `index.md` in a `_pages` folder. Point `layout` at whatever wraps your pages in `<html>` and loads your CSS (swap `default` for your theme's layout name):

{% raw %}
```html
---
title: Sitemap
permalink: /sitemap-index/
layout: default
---

<input type="text" id="searchBar" placeholder="Filter by anything…">

<table id="sitemap" class="table">
  <thead>
    <tr>
      <th data-type="string">Collection</th>
      <th data-type="string">Page</th>
      <th data-type="date">Date</th>
      <th data-type="string">Tags</th>
      <th data-type="string">Author</th>
    </tr>
  </thead>
  <tbody>
    {% for collection in site.collections %}
      {% for item in collection.docs %}
      <tr>
        <td>{{ collection.label }}</td>
        <td><a href="{{ item.url | relative_url }}">{{ item.title }}</a></td>
        <td data-sort="{{ item.date | date: '%Y-%m-%d' }}">{{ item.date | date: "%B %-d, %Y" }}</td>
        <td>{{ item.tags | join: ", " }}</td>
        <td>{{ item.author }}</td>
      </tr>
      {% endfor %}
    {% endfor %}
  </tbody>
</table>
```
{% endraw %}

Two choices in there are load-bearing, and they're the difference between this working and you debugging it for an afternoon:

- `{% raw %}{{ item.url | relative_url }}{% endraw %}`, not `{% raw %}{{ site.url }}{{ item.url }}{% endraw %}`. The `relative_url` filter prepends your `baseurl`, so the links work on a project site served under `/repo/`. Hard-concatenating `site.url` produces an absolute link that 404s the moment you're not on a root domain.
- The date cell carries a **machine-sortable copy in `data-sort`** (`%Y-%m-%d`) while displaying the human format. That tiny attribute is what saves the sort in Step 3. Skip it and you get the bug we'll show you.

You'll know it worked when `bundle exec jekyll build` produces `_site/sitemap-index/index.html` and opening it shows one row per doc, grouped by collection, every title a working link.

## Step 2: A live filter box, no library

The search box filters rows as you type. Show a row if the typed text appears in **any** cell; hide it otherwise. That's the whole feature. This block and the next one go inside a single `<script>` tag at the bottom of the same page, below the table:

```javascript
const search = document.getElementById("searchBar");
const rows = Array.from(document.querySelectorAll("#sitemap tbody tr"));

search.addEventListener("input", () => {
  const q = search.value.toLowerCase();
  rows.forEach(row => {
    const hit = row.textContent.toLowerCase().includes(q);
    row.style.display = hit ? "" : "none";
  });
});
```

`row.textContent` already concatenates every cell's text, so you don't loop columns — you ask the whole row once. That avoids a real bug in the obvious version: looping cells and setting `display = "none"` on each miss means the *last* column you check can hide a row that an earlier column matched. Asking the row once sidesteps it entirely.

You'll know it worked when typing in the box shrinks the list immediately and deleting the text brings every row back.

## Step 3: Click-to-sort headers — and the part where it broke

This is where the source material for this post went sideways for a solid hour, so you get to skip the hour.

Attempt one was inline `onclick="sortTable(0)"` on each header with a bubble-sort over `innerHTML`. Clicking did nothing — no error, no sort, no console output. The fix was to drop inline handlers and attach real event listeners after the DOM is parsed. Once that worked, two more things were quietly wrong, and they're the useful part.

Here's the version that actually behaves:

```javascript
document.querySelectorAll("#sitemap th").forEach(header => {
  header.dataset.order = "desc";   // so the FIRST click flips to ascending
  header.addEventListener("click", () => {
    const table = document.getElementById("sitemap");
    const tbody = table.querySelector("tbody");
    const index = Array.from(header.parentNode.children).indexOf(header);
    const type  = header.dataset.type;
    const order = header.dataset.order === "asc" ? "desc" : "asc";

    const rows = Array.from(tbody.querySelectorAll("tr"));
    rows.sort((a, b) => {
      // dates: compare the machine-sortable data-sort, not the displayed text
      let av = type === "date"
        ? a.children[index].dataset.sort
        : a.children[index].textContent.trim().toLowerCase();
      let bv = type === "date"
        ? b.children[index].dataset.sort
        : b.children[index].textContent.trim().toLowerCase();
      const cmp = av < bv ? -1 : av > bv ? 1 : 0;
      return order === "asc" ? cmp : -cmp;
    });

    rows.forEach(row => tbody.appendChild(row));   // re-append in new order
    header.dataset.order = order;
  });
});
```

You'll know it worked when clicking **Collection** groups the rows alphabetically, clicking it again reverses them, and clicking **Date** orders them oldest-to-newest on the first click.

### Gotcha 1: dates sorted alphabetically

The first working sort compared the **displayed** date string with `localeCompare`. Dates formatted as `"May 24, 2024"` don't sort chronologically as strings — they sort by first letter. Here's the actual difference, which we ran in node:

```javascript
const dates = ["May 24, 2024", "January 2, 2025", "August 9, 2023", "December 1, 2024"];
console.log("as strings: ", [...dates].sort((a, b) => a.localeCompare(b)));
console.log("as dates:   ", [...dates].sort((a, b) => new Date(a) - new Date(b)));
```

Real output:

```text
as strings:  [ 'August 9, 2023', 'December 1, 2024', 'January 2, 2025', 'May 24, 2024' ]
as dates:    [ 'August 9, 2023', 'May 24, 2024', 'December 1, 2024', 'January 2, 2025' ]
```

The string sort puts December 2024 before January 2025 before May 2024 — alphabetical, not chronological, and completely wrong for a sitemap. That's why Step 1 emits `data-sort="{% raw %}{{ item.date | date: '%Y-%m-%d' }}{% endraw %}"`. ISO dates (`2024-05-24`) sort correctly *as strings*, so the sort comparison stays a plain `<`/`>` with no `Date` parsing in the hot loop. Format once in Liquid, compare as text.

### Gotcha 2: the first click sorted backwards

The toggle stores the current direction on the header and flips it. If you initialize every header to `"asc"`, the first click reads `"asc"`, sorts ascending, *then* stores `"desc"` — so the user's first click does nothing visible on an already-ascending column, and the arrow feels off by one. Initializing to `"desc"` (as above) means the first click computes `"asc"` and the list visibly sorts ascending — which is what people expect from a first click.

## A bonus you'll be tempted to add, and the trap in it

You'll want an Excerpt column. Resist the obvious `{% raw %}{{ item.excerpt }}{% endraw %}`: Jekyll's auto-excerpt is the first block of the doc rendered to **HTML**, so it arrives wrapped in `<p>…</p>` (and sometimes a stray code fence). Dumped into a `<td>` it renders fine, but it bloats every row and your filter starts matching on HTML tag names. If you want it, strip the markup and clamp the length:

{% raw %}
```html
<td>{{ item.excerpt | strip_html | strip_newlines | truncate: 120 }}</td>
```
{% endraw %}

`strip_html` removes the `<p>` wrapper, `strip_newlines` flattens it, `truncate` keeps the table readable. You'll know it worked when the column shows plain prose, not `<p>` tags, and your search stops matching the word "p".

## When this goes wrong

- **Empty `Author`/`Tags` cells.** Drafts and pages without front matter render blank cells. That's honest — it's telling you which docs are missing metadata. If a blank breaks your sort comparison, the `.trim()` in the comparator already guards it.
- **`item.date` on a collection without dates.** Pages in a non-post collection may have no `date`. The `data-sort` becomes an empty string and those rows sort to the top. Either add dates or drop the Date header's `data-type="date"`.
- **The table is huge.** This loads every row into the DOM at once. At a few hundred docs it's instant; at several thousand you'll feel the initial render. That's the ceiling — past it you actually do want a real search index, and you've earned the right to install one.

## The honest accounting

One Liquid loop, one input box, forty lines of JS. No plugins, no build step beyond Jekyll itself, no JavaScript framework, nothing to keep updated. It filters, it sorts, and it ships as static HTML that GitHub Pages serves without complaint.

The two bugs that cost the original author an afternoon — dates sorting alphabetically and the first click going the wrong way — are now two lines of prevention: format dates as ISO in a `data-sort` attribute, and initialize the toggle to `"desc"`. Paste the blocks, fix those two things up front, and you have a site index you'll actually use to find your own posts.
