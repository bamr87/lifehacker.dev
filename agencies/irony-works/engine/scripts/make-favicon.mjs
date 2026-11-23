#!/usr/bin/env node
// Generates favicon.ico (16+32px) from the same mark as assets/images/logo.svg:
// a broken ring — the expectation, and the point where it reverses.
// Committed output, reproducible input. Run: node engine/scripts/make-favicon.mjs
import { writeFileSync } from "node:fs";
import { root } from "./lib.mjs";

const INK = [0x1f, 0x1b, 0x1b]; // BGR
const PAPER = [0xd9, 0xe4, 0xe8];
const SS = 3; // supersampling factor

// Two gaps in the ring, centred on these angles (degrees), half-width 16°.
const GAPS = [22, 202];
const inGap = (deg) => GAPS.some((g) => Math.abs(((deg - g + 540) % 360) - 180) > 164);

function render(size) {
  // BGRA, bottom-up rows (BMP convention)
  const px = Buffer.alloc(size * size * 4);
  const c = (size - 1) / 2;
  const R = size / 2 - 0.5;
  const rIn = size * 0.27;
  const rOut = size * 0.38;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let disc = 0, ring = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const px_ = x + (sx + 0.5) / SS - 0.5;
          const py_ = y + (sy + 0.5) / SS - 0.5;
          const dx = px_ - c, dy = py_ - c;
          const d = Math.hypot(dx, dy);
          if (d <= R) disc++;
          if (d >= rIn && d <= rOut) {
            const deg = (Math.atan2(-dy, dx) * 180) / Math.PI;
            if (!inGap(deg)) ring++;
          }
        }
      }
      const n = SS * SS;
      const aDisc = disc / n, aRing = ring / n;
      if (aDisc === 0) continue; // transparent outside the coin

      // Composite paper ring over ink disc.
      const o = ((size - 1 - y) * size + x) * 4;
      for (let ch = 0; ch < 3; ch++) px[o + ch] = Math.round(INK[ch] * (1 - aRing) + PAPER[ch] * aRing);
      px[o + 3] = Math.round(255 * aDisc);
    }
  }
  return px;
}

function bmpFor(size) {
  const header = Buffer.alloc(40);
  header.writeUInt32LE(40, 0);
  header.writeInt32LE(size, 4);
  header.writeInt32LE(size * 2, 8); // XOR + AND masks
  header.writeUInt16LE(1, 12);
  header.writeUInt16LE(32, 14);
  const maskRow = Math.ceil(size / 32) * 4; // 1bpp, padded to 4 bytes
  const mask = Buffer.alloc(maskRow * size); // all zero = "use alpha"
  return Buffer.concat([header, render(size), mask]);
}

const sizes = [16, 32];
const images = sizes.map(bmpFor);

const dir = Buffer.alloc(6);
dir.writeUInt16LE(0, 0);
dir.writeUInt16LE(1, 2);
dir.writeUInt16LE(sizes.length, 4);

let offset = 6 + 16 * sizes.length;
const entries = sizes.map((s, i) => {
  const e = Buffer.alloc(16);
  e.writeUInt8(s % 256, 0);
  e.writeUInt8(s % 256, 1);
  e.writeUInt8(0, 2);
  e.writeUInt8(0, 3);
  e.writeUInt16LE(1, 4);
  e.writeUInt16LE(32, 6);
  e.writeUInt32LE(images[i].length, 8);
  e.writeUInt32LE(offset, 12);
  offset += images[i].length;
  return e;
});

const ico = Buffer.concat([dir, ...entries, ...images]);
writeFileSync(root("favicon.ico"), ico);
console.log(`Wrote favicon.ico (${sizes.join("+")}px, ${ico.length} bytes)`);
