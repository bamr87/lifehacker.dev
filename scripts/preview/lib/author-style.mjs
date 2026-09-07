// Per-author Trace Bloom identity. design.json `authors.<key>` overrides the
// section lattice/palette for every article with that `author:` byline.

export function authorStyle(design, author) {
  if (!author || !design || !design.authors) return null;
  return design.authors[author] || null;
}

export function resolvePalette(design, section, author) {
  const style = authorStyle(design, author);
  if (style && style.palette) return style.palette;
  const sec = (design.sections && design.sections[section]) || (design.sections && design.sections['field-notes']);
  return sec.palette;
}

export function resolveLattice(design, section, author) {
  const style = authorStyle(design, author);
  if (style && style.lattice) return style.lattice;
  const sec = (design.sections && design.sections[section]) || (design.sections && design.sections['field-notes']);
  return sec.lattice;
}
