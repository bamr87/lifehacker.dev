#!/usr/bin/env ruby
# frozen_string_literal: true
#
# generate-favicon.rb — mint a member repo's browser-identity assets.
#
# WHY THIS EXISTS
#   The theme's _includes/core/favicon.html emits `<link rel="icon"
#   href="{{ favicon.ico | relative_url }}">` on every page and its own
#   comment assumes "every consumer site carries one at root". jekyll-remote-theme
#   copies only _layouts/_includes/_sass/assets from the theme, so the theme's
#   root favicon.ico never reaches a consumer — and no fleet member ever shipped
#   its own. Every member 404'd on /<repo>/favicon.ico.
#
#   Members are content-only repos with no rasterizer on any runner, so this
#   writes the .ico by hand (a 32x32 RGBA PNG in an ICO container, via Zlib
#   from stdlib) alongside a matching SVG. No toolchain, no binary deps.
#
# DESIGN
#   The mark is the repo's label (a 4-digit year) in a 3x5 pixel font, stacked
#   two digits over two, on a gradient whose hue is derived from the label — so
#   1776 and 1777 are distinguishable in a tab bar. Pixel-grid art matches the
#   fleet's preview art direction (lineage/policy.yml `preview.style`).
#
# USAGE
#   ruby scripts/generate-favicon.rb --repo ../1776 --label 1776
#   ruby scripts/generate-favicon.rb --repo ../1776 --label 1776 --dry-run
#   ruby scripts/generate-favicon.rb --repo ../1776 --label 1776 --hue 291
#
# WRITES
#   <repo>/favicon.ico                 32x32, the theme's `favicon.ico` link
#   <repo>/assets/images/favicon.svg   scalable, the theme's `favicon.svg` link

require 'optparse'
require 'fileutils'
require 'zlib'

# 3x5 pixel font, digits only — the fleet's labels are years.
GLYPHS = {
  '0' => %w[111 101 101 101 111], '1' => %w[010 110 010 010 111],
  '2' => %w[111 001 111 100 111], '3' => %w[111 001 111 001 111],
  '4' => %w[101 101 111 001 001], '5' => %w[111 100 111 001 111],
  '6' => %w[111 100 111 101 111], '7' => %w[111 001 001 001 001],
  '8' => %w[111 101 111 101 111], '9' => %w[111 101 111 001 111]
}.freeze

SIZE = 32 # icon edge, px

# --- color ------------------------------------------------------------------

# Deterministic hue per label. The *47 spread keeps consecutive years far
# apart on the wheel (1776 -> 291, 1777 -> 338) instead of one degree apart.
def hue_for(label)
  (label.bytes.sum * 47) % 360
end

def hsl_to_rgb(h, s, l)
  c = (1 - (2 * l - 1).abs) * s
  x = c * (1 - (((h / 60.0) % 2) - 1).abs)
  m = l - c / 2
  r, g, b = case h
            when 0...60    then [c, x, 0] when 60...120  then [x, c, 0]
            when 120...180 then [0, c, x] when 180...240 then [0, x, c]
            when 240...300 then [x, 0, c] else                [c, 0, x]
            end
  [r, g, b].map { |v| ((v + m) * 255).round.clamp(0, 255) }
end

def hex(rgb) = format('#%02x%02x%02x', *rgb)

# --- the mark ---------------------------------------------------------------

# Lit blocks of the label, laid out as two rows of two digits on a SIZE grid.
# scale 2 -> each digit 6x10, rows 14 wide and 22 tall together, centred.
def mark_blocks(label, scale: 2)
  chars = label.to_s.chars.select { |c| GLYPHS.key?(c) }
  return [] if chars.empty?

  per_row  = (chars.length / 2.0).ceil
  rows     = chars.each_slice(per_row).to_a
  gap      = scale
  row_w    = rows.map { |r| r.length * 3 * scale + (r.length - 1) * gap }.max
  block_h  = rows.length * 5 * scale + (rows.length - 1) * gap
  origin_x = ((SIZE - row_w) / 2.0).round
  origin_y = ((SIZE - block_h) / 2.0).round

  blocks = []
  rows.each_with_index do |row, ri|
    # Centre a short final row (odd-length labels) against the widest row.
    this_w = row.length * 3 * scale + (row.length - 1) * gap
    rx = origin_x + ((row_w - this_w) / 2.0).round
    row.each_with_index do |ch, ci|
      gx = rx + ci * (3 * scale + gap)
      gy = origin_y + ri * (5 * scale + gap)
      GLYPHS[ch].each_with_index do |bits, by|
        bits.chars.each_with_index do |bit, bx|
          next unless bit == '1'
          blocks << [gx + bx * scale, gy + by * scale, scale, scale]
        end
      end
    end
  end
  blocks
end

# The same mark expanded to individual pixels, for the raster writer.
def mark_pixels(label, scale: 2)
  mark_blocks(label, scale: scale).flat_map do |(x, y, w, h)|
    h.times.flat_map { |dy| w.times.map { |dx| [x + dx, y + dy] } }
  end
end

# Corner pixels to punch transparent, so the .ico reads as a rounded chip like
# the SVG's rx. Radius 5 on a 32px edge.
def rounded_corner?(x, y, r = 5)
  cx = x < r ? r - 0.5 : (x > SIZE - 1 - r ? SIZE - r - 0.5 : x)
  cy = y < r ? r - 0.5 : (y > SIZE - 1 - r ? SIZE - r - 0.5 : y)
  return false if cx == x && cy == y

  Math.sqrt((x - cx)**2 + (y - cy)**2) > r
end

# --- PNG / ICO writers ------------------------------------------------------

def png_chunk(type, data)
  [data.bytesize].pack('N') + type + data +
    [Zlib.crc32(type + data)].pack('N')
end

# 32-bit RGBA PNG from a SIZE*SIZE array of [r,g,b,a].
def png(pixels)
  raw = +''
  SIZE.times do |y|
    raw << "\x00" # filter type 0 (None)
    SIZE.times { |x| raw << pixels[y * SIZE + x].pack('C4') }
  end
  "\x89PNG\r\n\x1a\n".b +
    png_chunk('IHDR', [SIZE, SIZE].pack('N2') + [8, 6, 0, 0, 0].pack('C5')) +
    png_chunk('IDAT', Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION)) +
    png_chunk('IEND', '')
end

# ICO container around a single PNG payload (PNG-in-ICO, universally supported
# by every browser the theme targets).
def ico(png_bytes)
  [0, 1, 1].pack('v3') +
    [SIZE, SIZE, 0, 0].pack('C4') + [1, 32].pack('v2') +
    [png_bytes.bytesize, 22].pack('V2') +
    png_bytes
end

# --- renderers --------------------------------------------------------------

def render_ico(label, top, bottom)
  lit = mark_pixels(label).each_with_object({}) { |p, h| h[p] = true }

  pixels = Array.new(SIZE * SIZE)
  SIZE.times do |y|
    SIZE.times do |x|
      if rounded_corner?(x, y)
        pixels[y * SIZE + x] = [0, 0, 0, 0]
        next
      end
      # Diagonal gradient: 0 at top-left, 1 at bottom-right.
      t = (x + y) / (2.0 * (SIZE - 1))
      bg = [0, 1, 2].map { |i| (top[i] + (bottom[i] - top[i]) * t).round }
      pixels[y * SIZE + x] =
        lit[[x, y]] ? [255, 255, 255, 255] : (bg + [255])
    end
  end
  ico(png(pixels))
end

def render_svg(label, top, bottom)
  rects = mark_blocks(label)
          .map { |(x, y, w, h)| %(<rect x="#{x}" y="#{y}" width="#{w}" height="#{h}"/>) }
          .each_slice(6).map { |s| "    #{s.join}" }.join("\n")
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{SIZE} #{SIZE}" width="#{SIZE}" height="#{SIZE}" role="img" aria-label="#{label}">
      <defs>
        <linearGradient id="f" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#{hex(top)}"/>
          <stop offset="1" stop-color="#{hex(bottom)}"/>
        </linearGradient>
      </defs>
      <rect width="#{SIZE}" height="#{SIZE}" rx="5" fill="url(#f)"/>
      <g fill="#ffffff" shape-rendering="crispEdges">
    #{rects.strip.empty? ? '' : rects}
      </g>
    </svg>
  SVG
end

# --- main -------------------------------------------------------------------

options = { repo: '.', dry_run: false }
OptionParser.new do |o|
  o.banner = 'Usage: ruby scripts/generate-favicon.rb --repo PATH --label YEAR [options]'
  o.on('--repo PATH',  'Target repo root (default: .)')            { |v| options[:repo] = v }
  o.on('--label TEXT', 'Digits to render (default: repo basename)') { |v| options[:label] = v }
  o.on('--hue DEG',    Integer, 'Override the derived hue (0-359)') { |v| options[:hue] = v }
  o.on('--dry-run',    'Report what would be written, write nothing') { options[:dry_run] = true }
  o.on('-h', '--help') { puts o; exit }
end.parse!

repo  = File.expand_path(options[:repo])
label = (options[:label] || File.basename(repo)).to_s
abort "generate-favicon: no renderable digits in label #{label.inspect}" if mark_pixels(label).empty?

hue    = options[:hue] || hue_for(label)
top    = hsl_to_rgb(hue, 0.70, 0.55)
bottom = hsl_to_rgb((hue + 25) % 360, 0.65, 0.30)

targets = {
  File.join(repo, 'favicon.ico')                     => render_ico(label, top, bottom),
  File.join(repo, 'assets', 'images', 'favicon.svg') => render_svg(label, top, bottom)
}

targets.each do |path, content|
  rel = path.sub("#{repo}/", '')
  if options[:dry_run]
    puts "  would write  #{rel} (#{content.bytesize} bytes)"
    next
  end
  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, content)
  puts "  write  #{rel} (#{content.bytesize} bytes)"
end
puts "generate-favicon: #{label} @ hue #{hue} (#{hex(top)} -> #{hex(bottom)})"
