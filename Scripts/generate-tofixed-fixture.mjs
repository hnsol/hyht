#!/usr/bin/env node
// Generates the golden fixture used by HyhtCoreTests to prove that Swift's
// `jsToFixed(_:digits:)` matches JavaScript's `Number.prototype.toFixed`.
//
// The expected values are never hand-written: floating point makes them
// counter-intuitive (e.g. `(9.995).toFixed(2) === "9.99"`), so they are
// produced by actually running `toFixed` in Node.
//
// Usage:
//   node Scripts/generate-tofixed-fixture.mjs
//
// Output:
//   Packages/HyhtCore/Sources/HyhtCore/Resources/tofixed-fixture.json

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(SCRIPT_DIR, "..");
const OUTPUT_PATH = resolve(
  REPO_ROOT,
  "Packages/HyhtCore/Sources/HyhtCore/Resources/tofixed-fixture.json",
);

const SECONDS_PER_WEEK = 7 * 24 * 3600;
const SECONDS_PER_DAY = 24 * 3600;
const SECONDS_PER_HOUR = 3600;

/** Exact IEEE-754 bit pattern, so Swift can reconstruct the identical Double
 *  without depending on JSON number parsing. */
function bitsHex(value) {
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, value);
  return view.getBigUint64(0).toString(16).padStart(16, "0");
}

const cases = [];
const seen = new Set();

function add(value, digits, note) {
  const key = `${bitsHex(value)}:${digits}`;
  if (seen.has(key)) return;
  seen.add(key);
  cases.push({
    note,
    value,
    bitsHex: bitsHex(value),
    digits,
    expected: value.toFixed(digits),
  });
}

/** Adds the value at both fraction-digit counts the app uses, plus digits=0. */
function addAllDigits(value, note) {
  for (const digits of [0, 1, 2]) add(value, digits, note);
}

// ---- Classic half-way / representation traps -------------------------------
for (const value of [1.005, 2.675, 9.995, 0.125, 1.115, 8.575, 0.005, 1.045]) {
  addAllDigits(value, "half-way trap");
}

// ---- Exact binary ties (round half up, away from zero) ---------------------
for (const value of [0.5, 1.5, 2.5, 3.5, 0.25, 0.75, 1.25, 1.75, 0.0625]) {
  addAllDigits(value, "exact binary tie");
}

// ---- Trailing zeros / decimal point preserved ------------------------------
for (const value of [0, 1, 1.2, 1.5, 12, 100, 120, 120.0, 0.1, 0.10]) {
  addAllDigits(value, "trailing zeros");
}

// ---- Carry / digit growth --------------------------------------------------
for (const value of [9.999, 0.999, 99.995, 9.95, 9.99, 99.99, 0.99, 0.09, 0.049]) {
  addAllDigits(value, "carry");
}

// ---- Small magnitudes ------------------------------------------------------
for (const value of [0.0001, 0.004999999, 5e-7, 1e-10]) {
  addAllDigits(value, "small magnitude");
}

// ---- Negative values (out of the app's domain, but behaviour is pinned) ----
for (const value of [-1.005, -0.5, -2.675, -0.125, -120.0]) {
  addAllDigits(value, "negative");
}
add(-0, 2, "negative zero");

// ---- Representative countdown values --------------------------------------
// week mode: remaining / (7 * 86400), toFixed(2)
const WEEK_REMAINDERS = [
  12 * SECONDS_PER_DAY + 31, // just inside the week boundary
  12.5 * SECONDS_PER_DAY,
  13 * SECONDS_PER_DAY,
  20 * SECONDS_PER_DAY,
  50 * SECONDS_PER_DAY,
  100 * SECONDS_PER_DAY,
  365 * SECONDS_PER_DAY,
  12.34 * SECONDS_PER_WEEK,
  1.005 * SECONDS_PER_WEEK,
  9.995 * SECONDS_PER_WEEK,
];
for (const remaining of WEEK_REMAINDERS) {
  add(remaining / SECONDS_PER_WEEK, 2, "week mode value");
}

// day mode: remaining / 86400, toFixed(2)
const DAY_REMAINDERS = [
  120 * SECONDS_PER_HOUR + 31, // just inside the day boundary
  12 * SECONDS_PER_DAY + 30, // just outside the week boundary
  6.42 * SECONDS_PER_DAY,
  7 * SECONDS_PER_DAY,
  9.995 * SECONDS_PER_DAY,
  10 * SECONDS_PER_DAY,
  5.125 * SECONDS_PER_DAY,
  11.999 * SECONDS_PER_DAY,
];
for (const remaining of DAY_REMAINDERS) {
  add(remaining / SECONDS_PER_DAY, 2, "day mode value");
}

// hour mode: remaining / 3600, toFixed(1)
const HOUR_REMAINDERS = [
  24 * SECONDS_PER_HOUR + 31, // just inside the hour boundary
  120 * SECONDS_PER_HOUR + 30, // just outside the day boundary
  48.5 * SECONDS_PER_HOUR,
  99.95 * SECONDS_PER_HOUR,
  100 * SECONDS_PER_HOUR,
  119.99 * SECONDS_PER_HOUR,
  24.05 * SECONDS_PER_HOUR,
  36.25 * SECONDS_PER_HOUR,
];
for (const remaining of HOUR_REMAINDERS) {
  add(remaining / SECONDS_PER_HOUR, 1, "hour mode value");
}

// ---- Dense sweep over each mode's whole range ------------------------------
// One value per minute is overkill; sample every 997 seconds (a prime, so the
// samples do not align with any boundary) across each mode's full span.
for (let remaining = 12 * SECONDS_PER_DAY + 31; remaining < 400 * SECONDS_PER_DAY; remaining += 99991) {
  add(remaining / SECONDS_PER_WEEK, 2, "week mode sweep");
}
for (let remaining = 120 * SECONDS_PER_HOUR + 31; remaining <= 12 * SECONDS_PER_DAY + 30; remaining += 997) {
  add(remaining / SECONDS_PER_DAY, 2, "day mode sweep");
}
for (let remaining = 24 * SECONDS_PER_HOUR + 31; remaining <= 120 * SECONDS_PER_HOUR + 30; remaining += 997) {
  add(remaining / SECONDS_PER_HOUR, 1, "hour mode sweep");
}

// ---- Deterministic pseudo-random sweep ------------------------------------
// A fixed-seed LCG keeps the fixture reproducible while still exercising
// arbitrary bit patterns that the hand-picked cases would miss.
let seed = 0x2f6e2b1;
function nextRandom() {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}
for (let i = 0; i < 400; i += 1) {
  // Spread across the magnitudes the app can produce (~1e-3 .. ~1e3).
  const value = nextRandom() * 10 ** (Math.floor(nextRandom() * 7) - 3);
  add(value, i % 2 === 0 ? 2 : 1, "random sweep");
}

const fixture = {
  description:
    "Golden values produced by JavaScript's Number.prototype.toFixed. Regenerate with `node Scripts/generate-tofixed-fixture.mjs`.",
  generator: "Scripts/generate-tofixed-fixture.mjs",
  caseCount: cases.length,
  cases,
};

mkdirSync(dirname(OUTPUT_PATH), { recursive: true });
writeFileSync(OUTPUT_PATH, `${JSON.stringify(fixture, null, 2)}\n`, "utf8");
console.log(`Wrote ${cases.length} cases to ${OUTPUT_PATH}`);
