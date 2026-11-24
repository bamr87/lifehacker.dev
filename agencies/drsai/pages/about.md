---
title: "How drsai makes a book"
description: "The pipeline behind the storybooks: an OpenAI-powered story engine, prompt-driven watercolor illustration, and a Jekyll books collection on GitHub Pages."
layout: default
permalink: /about/
sidebar: false
toc: true
---

**drsai** is a children's book platform: every book on this site is written with AI assistance, illustrated by AI image models, and published as a real, readable picture book on GitHub Pages.

## The four repos

| Repo | Role |
|---|---|
| [drsai](https://github.com/bamr87/drsai) | This site — the platform. Hosts the books collection, the import/generation tools, and the Python story engine (`drsai/`). |
| [Dodge-and-Reena-Book](https://github.com/bamr87/Dodge-and-Reena-Book) | The first book's content repo: canonical story text, the illustration style & character bible, and chosen AI renders. |
| [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) | The Jekyll theme. Its `books` collection, layouts, and components turn markdown into a picture book. |
| [zer0-image-generator](https://github.com/bamr87/zer0-image-generator) | The `jekyll preview-images` gem — OpenAI-rendered social/preview banners for every story page. |

## The words

The [drsai story engine](https://github.com/bamr87/drsai/tree/main/drsai) generates Seuss-style verse and prose with OpenAI models (Anthropic and xAI are supported too), then validates what comes back: a scansion engine checks anapestic tetrameter, a rhyme checker scores the couplets. Drafts get refined by hand in the book's content repo — the AI is the pen, not the author.

## The pictures

Each story page carries an `illustrations:` list in its front matter: three scenes per story (Setup → Mystery → Resolution), each with a self-contained prompt that quotes the book's **style and character bible** verbatim, so Deputy Dodge wears the same oversized tan hat in July as he does in January.

Missing scenes are rendered with the OpenAI Images API by [`tools/generate_illustrations.py`](https://github.com/bamr87/drsai/blob/main/tools/generate_illustrations.py); every story's colophon (the "How the illustrations were made" fold at the bottom) shows the exact prompts, so the art is reproducible and the process is transparent.

## The book

The [zer0-mistakes theme](https://github.com/bamr87/zer0-mistakes) provides the `books` collection: a landing page with cover hero and table of contents, immersive story pages with a storybook serif and full-width plates, and prev/next navigation that reads cover to cover. Content is imported from the book's repo by [`tools/import_dodge_and_reena.py`](https://github.com/bamr87/drsai/blob/main/tools/import_dodge_and_reena.py) — stories in, book out.

## Read the test book

[**Deputy Dodge & Ranger Reena: Adventures of a Lifetime**](/books/dodge-and-reena/) — twelve gentle mysteries in the desert town of Dusty Gulch, one for every month of the year.
