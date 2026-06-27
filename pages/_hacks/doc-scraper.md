---
title: "Document Scraping in Python: BeautifulSoup, Playwright, and the Failure Modes That Bite First"
description: "Scrape structured data with Python: BeautifulSoup vs Playwright, a stdlib parser you can run now, robots.txt, dedup, and the crash that bites first."
date: 2024-05-01
collection: hacks
author: amr
excerpt: "Most data worth having is locked in HTML that was never meant to be queried. Here's the scraper, the dedup trick, and the one malformed row that kills the whole run."
tags: [python, web-scraping, beautifulsoup, playwright, html]
---

Somewhere there is a dashboard that promises to turn any website into a clean spreadsheet with one click. You will pay for it, and it will work on exactly the page in the demo video.

Real scraping is less of a click and more of a negotiation. Every site is shaped differently, half of them render their data after the page loads, and the one row that breaks your run is always row two. This is the part that actually pulls the data out, including the part where it broke.

A note before the code: the production tools here — `requests`, `BeautifulSoup`, `Playwright` — need `pip install` and, for some examples, a network connection. So the runnable demonstrations below use only Python's standard library (`html.parser`, `sqlite3`, `urllib.robotparser`), which ships with every Python install. The logic is identical; the dependency list is zero. We ran every Python block on this host (Python 3.14) and pasted the real output.

## Pick the tool by how the page hides its data

Three tools cover almost everything. The choice is not about taste, it is about where the data lives.

| Tool | Use it when |
|---|---|
| `requests` + `BeautifulSoup` | The data is already in the HTML you get back from a plain GET. Smallest surface area, fastest to debug. |
| `Scrapy` | You are crawling thousands of pages and following links. Built-in throttling and retry. |
| `Playwright` / `Selenium` | The raw HTML is mostly empty `<div>`s and the data only appears after JavaScript runs, a scroll, or a login. |

The deciding test is one command. Fetch the page and look for your data in the raw response:

```bash
# lh:run
# Does the data live in the static HTML, or does JS paint it in later?
# Replace the URL and the word you're hunting for. If grep finds it, BeautifulSoup is enough.
html=$(curl -s https://example.com/)
echo "$html" | grep -c "Example Domain"   # >0 means the text is in the raw HTML
echo "$html" | wc -c                       # how much body the server actually sent
```

We ran that against `example.com`. The real output:

```
1
     559
```

The phrase is in the raw HTML, so a plain GET would see it — no browser needed. When that first number comes back `0` but the page clearly shows the text in your browser, the data is painted in by JavaScript, and that is your signal to reach for Playwright. The byte count is the other tell: a JS-rendered app often ships a tiny shell of empty `<div>`s and loads everything else over XHR, so a body far smaller than the page you see means the content arrives later. You'll know which world you are in before you write a single line of parser.

## The parser, stdlib only, that you can run right now

`BeautifulSoup` is the nicer API, but the model underneath is the same one in `html.parser`: walk the tags, grab text and attributes off the ones you care about. Here is a complete extractor with no dependencies. It parses a small "results page" — the shape every archive, listing, and search page collapses to — into rows.

```python
from html.parser import HTMLParser
import sqlite3

# A tiny "results page" — the shape every list/archive site reduces to.
HTML = """
<div class="result-item">
  <h2 class="title">First Report</h2>
  <span class="date">2024-05-01</span>
  <a href="/reports/1">read</a>
</div>
<div class="result-item">
  <h2 class="title">Second Report</h2>
  <span class="date">2024-05-02</span>
  <a href="/reports/2">read</a>
</div>
"""

class ResultParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows, self.cur, self.grab = [], None, None
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "div" and a.get("class") == "result-item":
            self.cur = {"title": "", "date": "", "link": ""}  # default every field
        elif tag == "h2" and a.get("class") == "title":
            self.grab = "title"
        elif tag == "span" and a.get("class") == "date":
            self.grab = "date"
        elif tag == "a" and self.cur is not None:
            self.cur["link"] = a.get("href", "")             # .get, never [ ]
    def handle_data(self, data):
        if self.grab and self.cur is not None and data.strip():
            self.cur[self.grab] = data.strip()
            self.grab = None
    def handle_endtag(self, tag):
        if tag == "div" and self.cur is not None:
            self.rows.append(self.cur)
            self.cur = None

p = ResultParser()
p.feed(HTML)
for r in p.rows:
    print(r)

# Store with a UNIQUE key so a re-run never double-counts.
conn = sqlite3.connect(":memory:")
conn.execute("CREATE TABLE results (title TEXT, date TEXT, link TEXT UNIQUE)")
batch = p.rows + [p.rows[0]]          # pretend the scrape resumed and re-saw row 1
for r in batch:
    conn.execute("INSERT OR IGNORE INTO results VALUES (?,?,?)",
                 (r["title"], r["date"], r["link"]))
conn.commit()
print("rows stored after a re-run of", len(batch), "inserts:",
      conn.execute("SELECT COUNT(*) FROM results").fetchone()[0])
```

We ran that. The real output:

```
{'title': 'First Report', 'date': '2024-05-01', 'link': '/reports/1'}
{'title': 'Second Report', 'date': '2024-05-02', 'link': '/reports/2'}
rows stored after a re-run of 3 inserts: 2
```

You'll know it worked when two things hold: every row has all three fields filled, and the stored count is `2` even though you inserted `3`. That second number is the whole storage strategy in one line.

The `BeautifulSoup` version of the extraction is shorter to write and reads the same way — keep it as the documentation target for real work:

```python
from bs4 import BeautifulSoup

soup = BeautifulSoup(html, "html.parser")
rows = []
for item in soup.select("div.result-item"):
    a = item.select_one("a")
    rows.append({
        "title": item.select_one("h2.title").get_text(strip=True),
        "date":  item.select_one("span.date").get_text(strip=True),
        "link":  a["href"] if a else "",
    })
```

Two things carry over from the stdlib version and matter more than the syntax: `if a else ""` instead of `a["href"]`, and never assuming `select_one` found anything. Skip them and you write the crash in the next section.

## The part where it broke: row two had no date

The first version of the parser assumed every result row was complete. Most were. One was a draft the site hadn't finished publishing — it had a title and nothing else. Here is that exact situation, reduced:

```python
from html.parser import HTMLParser

HTML = """
<div class="result-item"><h2 class="title">Full row</h2><span class="date">2024-05-01</span></div>
<div class="result-item"><h2 class="title">Draft row</h2></div>
"""

class P(HTMLParser):
    def __init__(self):
        super().__init__(); self.cur=None; self.grab=None
    def handle_starttag(self, t, a):
        a = dict(a)
        if t == "div" and a.get("class") == "result-item": self.cur = {}
        elif t == "h2": self.grab = "title"
        elif t == "span" and a.get("class") == "date": self.grab = "date"
    def handle_data(self, d):
        if self.grab and d.strip(): self.cur[self.grab] = d.strip(); self.grab = None
    def handle_endtag(self, t):
        if t == "div" and self.cur is not None:
            print(self.cur["title"], "scraped on", self.cur["date"])  # assumes 'date' exists
            self.cur = None

P().feed(HTML)
```

We ran that. The real output:

```
Full row scraped on 2024-05-01
Traceback (most recent call last):
  ...
    print(self.cur["title"], "scraped on", self.cur["date"])
                                           ~~~~~~~~^^^^^^^^
KeyError: 'date'
```

Row one prints. Row two raises `KeyError: 'date'` and the whole run dies — including the rows you already collected, if you weren't writing them out as you went. One malformed row out of a thousand takes the entire scrape down with it.

This is the failure that bites first, every time, on every site. Pages are written by humans and CMSs that forget a field, ship a draft, or A/B-test a new layout on 5% of rows. Your parser meets all of those on the same run.

The fix is two habits, both visible in the working parser above:

- Initialize every field to a default (`{"title": "", "date": "", "link": ""}`) when the row starts, so a missing field is an empty string, not a missing key.
- Read attributes with `a.get("href", "")`, never `a["href"]`, and never assume a selector matched.

Defensive parsing looks paranoid until row two, and then it looks like the only sane way to write the thing.

## Check robots.txt before you run at volume

A scraper that ignores `robots.txt` is the reason scrapers get a bad name. `urllib.robotparser` reads the rules so you can ask, per URL, whether you are allowed. You can parse a rules string directly with no network:

```python
from urllib import robotparser

rp = robotparser.RobotFileParser()
rp.parse("""User-agent: *
Disallow: /private/
Allow: /data/
""".splitlines())

print("can fetch /data/page-1 :", rp.can_fetch("*", "https://example.com/data/page-1"))
print("can fetch /private/x   :", rp.can_fetch("*", "https://example.com/private/x"))
```

We ran that. The real output:

```
can fetch /data/page-1 : True
can fetch /private/x   : False
```

In production you point it at the live file with `rp.set_url("https://example.com/robots.txt"); rp.read()` and then gate every request behind `rp.can_fetch(...)`. You'll know it worked when your crawler quietly skips the disallowed paths instead of marching into them.

## Be polite, or get blocked

The other reason scrapers get blocked is volume without pauses. Real machines do not request 50 pages a second. Add jitter so your timing does not look like a metronome:

```python
import time, random, requests

for url in urls:
    resp = requests.get(url, headers={"User-Agent": "research-bot/1.0 (contact: you@example.com)"})
    resp.raise_for_status()
    process(resp)
    time.sleep(random.uniform(1.5, 3.5))  # random gap, not a fixed cadence
```

A fixed `time.sleep(2)` is itself a pattern a rate limiter can spot. The `random.uniform` gap is the cheapest defense against "you got blocked after request 200 and don't know why."

## When this goes wrong elsewhere

- **Selector breaks after a redesign.** Positional CSS paths (`div > div:nth-child(3)`) snap the moment the page shifts. Target `data-*` attributes or stable IDs instead — they survive cosmetic redesigns that move things around.
- **The page is empty in `requests` but full in your browser.** That is JavaScript rendering. `requests` only sees the initial HTML. Switch to Playwright and wait for the element by name, not by clock:

  ```python
  from playwright.sync_api import sync_playwright

  with sync_playwright() as p:
      browser = p.chromium.launch()
      page = browser.new_page()
      page.goto("https://example.com/data")
      page.wait_for_selector("table.results")   # blocks until the data exists, not a fixed sleep
      html = page.content()
      browser.close()
  ```

  `wait_for_selector` is the fix for the flaky `time.sleep(5)` you would otherwise sprinkle everywhere — it waits exactly as long as the page takes and no longer.
- **Mojibake: `CafÃ©` instead of `Café`.** When a server does not declare a charset, the bytes get decoded with the wrong codec. The repro and the fix:

  ```python
  raw = "Café résumé".encode("utf-8")
  print("wrong (latin-1):", raw.decode("latin-1"))
  print("right  (utf-8) :", raw.decode("utf-8"))
  ```

  We ran that. The real output:

  ```
  wrong (latin-1): CafÃ© rÃ©sumÃ©
  right  (utf-8) : Café résumé
  ```

  With `requests`, the move is `resp.encoding = resp.apparent_encoding` before you read `resp.text`. The garbled accents are the tell that you decoded the right bytes the wrong way.
- **Pagination stops on page one.** Check whether "next" is an `<a href>` or a JavaScript click. A real link you can follow with `requests`; a JS event needs Playwright to fire it.

## The honest accounting

This does not scrape any site automatically and it never will, because every site is different on purpose. What the stdlib version gives you is a parser you can run this second with zero installs, a storage pattern that survives re-runs without duplicating rows, and — the part most tutorials skip — a parser that does not fall over the first time a row is missing a field.

The real skill in scraping is not the happy path. It is assuming row two is broken and writing the code that survives it anyway.
