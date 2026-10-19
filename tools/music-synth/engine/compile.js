// Compiles music into timed note events (seconds), for the offline renderer (offline.js) and the
// statistics (render.mjs --stats). Pure JS: runs in Node and in the browser.
//
// Two inputs:
// - an ORIGINAL THEME of the Phaser version (synth/data/musicThemes.js), compiled exactly as
//   synth/audio/music.js plays it (same notation, same layers, same `every` / `from` / variants);
// - a SCORE (scores/*.js): the same notation, cut into SECTIONS, each with its own tempo, metre,
//   chords and layers, plus a few additions (see README.md § Partition).
//
// The notation helpers below are copied from synth/audio/music.js (unchanged), with a few more chord
// qualities and slash chords ("D/F#") added.

const PITCH = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
export const QUALITY = {
  "": [0, 4, 7], m: [0, 3, 7], 7: [0, 4, 7, 10], m7: [0, 3, 7, 10], maj7: [0, 4, 7, 11], m9: [0, 3, 7, 10, 14],
  sus2: [0, 2, 7], sus4: [0, 5, 7], dim: [0, 3, 6], aug: [0, 4, 8], add9: [0, 4, 7, 14], 5: [0, 7], 6: [0, 4, 7, 9], m6: [0, 3, 7, 9],
  // (added for the scores)
  m7b5: [0, 3, 6, 10], maj9: [0, 4, 7, 11, 14], "7sus4": [0, 5, 7, 10], madd9: [0, 3, 7, 14], 69: [0, 4, 7, 9, 14], dim7: [0, 3, 6, 9],
  9: [0, 4, 7, 10, 14], "maj7#11": [0, 4, 7, 11, 18],
};

export function noteToMidi(tok) {
  const m = tok.match(/^([A-G])([#b]?)(-?\d)$/);
  if (!m) throw new Error(`Note inconnue : ${tok}`);
  return 12 * (+m[3] + 1) + PITCH[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0);
}

const pc = (name, acc) => (PITCH[name] + (acc === "#" ? 1 : acc === "b" ? -1 : 0) + 12) % 12;

export function parseChord(sym) {
  const [main, slash] = sym.split("/");
  const m = main.match(/^([A-G])([#b]?)(.*)$/);
  if (!m || !(m[3] in QUALITY)) throw new Error(`Accord inconnu : ${sym}`);
  const chord = { root: pc(m[1], m[2]), tones: QUALITY[m[3]] };
  if (slash) {
    const b = slash.match(/^([A-G])([#b]?)$/);
    if (!b) throw new Error(`Basse inconnue : ${sym}`);
    chord.bass = pc(b[1], b[2]);
  }
  return chord;
}

export const tokens = (s) => s.split(/\s+/).filter((t) => t && t !== "|");

// A chord degree ("1", "3", "5", "7", "8", "10", "12", "L5" = fifth below) as a MIDI note.
// (Added: "B" = the slash bass of the chord, else its root; "LB" an octave lower.)
function degree(chord, tok, base) {
  const low = tok.startsWith("L");
  const name = tok.replace("L", "");
  if (name === "B") return base + (chord.bass ?? chord.root) - (low ? 12 : 0);
  const n = +name;
  const t = chord.tones;
  const byDegree = { 1: t[0], 3: t[1], 5: t[2] ?? t[1], 7: t[3] ?? 12, 8: 12, 9: 14, 10: t[1] + 12, 12: (t[2] ?? t[1]) + 12, 15: t[1] + 24 };
  if (!(n in byDegree)) throw new Error(`Degré inconnu : ${tok}`);
  return base + chord.root + byDegree[n] - (low ? 12 : 0);
}

// Turns a token string into events { step: [{ midi, steps, vel }] } over `total` steps.
function sequence(toks, total, noteOf) {
  const ev = new Map();
  let last = null;
  for (let s = 0; s < total; s++) {
    const tok = toks[s % toks.length];
    if (tok === "-") { if (last) last.forEach((n) => n.steps++); continue; }
    last = null;
    if (tok === ".") continue;
    const notes = noteOf(tok, s);
    if (notes == null) continue;
    last = (Array.isArray(notes) ? notes : [notes]).map((midi) => ({ midi, steps: 1, vel: 1 }));
    ev.set(s, last);
  }
  return ev;
}

// ---------------------------------------------------------------- generated melodies (music.js)
function rng(seed) {
  let s = seed >>> 0 || 1;
  return () => ((s = Math.imul(s ^ (s >>> 15), 2246822507) ^ Math.imul(s ^ (s >>> 13), 3266489909)) >>> 0) / 4294967296;
}

const RHYTHMS = [
  "x - - x - - x -", "x - x - x - - -", "x - - - x - x -", "x x x - x - - -", "x - - - - - x x", "x - x x - - x -",
];

function generate(theme, layer, chords, spb, seed) {
  const rand = rng(seed);
  const scale = theme.scale.map((d) => d + theme.key);
  const lo = 12 * (layer.oct + 1), hi = lo + 14;
  const inScale = [];
  for (let m = lo - 12; m <= hi + 12; m++) if (scale.some((d) => (m - d) % 12 === 0)) inScale.push(m);
  const ev = new Map();
  let prev = lo + 7;
  const motifs = [];
  chords.forEach((chord, bar) => {
    const rhythm = bar % 2 && motifs.length ? motifs[motifs.length - 1] : tokens(RHYTHMS[Math.floor(rand() * RHYTHMS.length)]);
    motifs.push(rhythm);
    const end = bar === chords.length - 1;
    let last = null;
    for (let i = 0; i < spb; i++) {
      const tok = rhythm[i % rhythm.length];
      if (tok === "-") { if (last) last.steps++; continue; }
      last = null;
      if (tok !== "x" || rand() > layer.density) continue;
      let midi;
      if (i === 0 || i === spb / 2 || end) {
        const tones = inScale.filter((m) => chord.tones.some((t) => (m - chord.root - t) % 12 === 0) && m >= lo && m <= hi);
        midi = tones.reduce((a, b) => (Math.abs(b - prev) < Math.abs(a - prev) ? b : a), tones[0]);
        if (rand() < 0.3) midi = tones[Math.floor(rand() * tones.length)];
      } else {
        const idx = inScale.indexOf(inScale.reduce((a, b) => (Math.abs(b - prev) < Math.abs(a - prev) ? b : a)));
        const stepBy = [-2, -1, -1, 1, 1, 2][Math.floor(rand() * 6)];
        midi = inScale[Math.min(inScale.length - 1, Math.max(0, idx + stepBy))];
        midi = Math.min(hi, Math.max(lo, midi));
      }
      prev = midi;
      last = { midi, steps: 1, vel: i === 0 ? 1 : 0.8 };
      ev.set(bar * spb + i, [last]);
    }
  });
  return ev;
}

// ---------------------------------------------------------------- additions for the scores
// A melody written by durations: "F#5:4 E5:2 D5:2 | E5:2 F#5:2 B4:4" (a duration in steps, 1 by
// default; "r" a rest; "-" ties on the note before; "C5+E5" several notes at once; suffixes on the
// pitch: "!" accent, "_" soft, "'" short (staccato)). Bars ("|") are checked against the metre.
const ACCENT = { "!": 1.25, _: 0.62 };

function parsePitches(p, transpose) {
  let vel = 1, stac = false, core = p;
  while (/[!_']$/.test(core)) {
    const c = core.slice(-1);
    if (c === "'") stac = true; else vel *= ACCENT[c];
    core = core.slice(0, -1);
  }
  return core.split("+").map((x) => ({ midi: noteToMidi(x) + transpose, vel, stac }));
}

function line(text, spb, total, transpose, where) {
  const ev = new Map();
  const bars = text.split("|").map((b) => b.trim()).filter(Boolean);
  let s = 0, last = null;
  bars.forEach((bar, bi) => {
    let inBar = 0;
    for (const item of bar.split(/\s+/)) {
      const [p, d] = item.split(":");
      const steps = d === undefined ? 1 : Number(d);
      if (!Number.isInteger(steps) || steps <= 0) throw new Error(`${where} : durée invalide « ${item} » (mesure ${bi + 1})`);
      if (p === "-") { if (!last) throw new Error(`${where} : liaison sans note (mesure ${bi + 1})`); last.forEach((n) => (n.steps += steps)); }
      else if (p === "r") last = null;
      else { last = parsePitches(p, transpose).map((n) => ({ ...n, steps })); ev.set(s, last); }
      s += steps;
      inBar += steps;
    }
    if (inBar !== spb) throw new Error(`${where} : la mesure ${bi + 1} fait ${inBar} pas au lieu de ${spb} (« ${bar} »)`);
  });
  if (s !== total) throw new Error(`${where} : la ligne fait ${s} pas au lieu de ${total}`);
  return ev;
}

// A strummed chord on each "d" (down: low to high) or "u" (up: the top strings, high to low).
function strum(l, chords, spb, total) {
  const toks = tokens(l.pat);
  const ev = new Map();
  const base = 12 * (l.oct + 1);
  let last = null;
  for (let s = 0; s < total; s++) {
    const tok = toks[s % toks.length];
    if (tok === "-") { if (last) last.forEach((n) => n.steps++); continue; }
    last = null;
    if (tok === ".") continue;
    const chord = chords[Math.floor(s / spb)];
    let degs = (l.strings || "1 5 8 10 12").split(/\s+/).map((d) => degree(chord, d, base));
    const up = tok === "u";
    if (up) degs = degs.slice(-3).reverse();
    last = degs.map((midi, k) => ({ midi, steps: 1, vel: up ? 0.7 : tok === "D" ? 1.15 : 1, delay: k * (l.spread ?? 0.012) }));
    ev.set(s, last);
  }
  return ev;
}

// Drums: "x" hit, "o" soft hit, "r" a roll of 4 rising hits within the step, "R" of 8.
function drums(l, total) {
  const ev = new Map();
  const toks = tokens(l.pat);
  for (let s = 0; s < total; s++) {
    const tok = toks[s % toks.length];
    if (tok === "x" || tok === "o") ev.set(s, [{ midi: 60, steps: 1, vel: tok === "x" ? 1 : 0.55 }]);
    else if (tok === "r" || tok === "R") {
      const n = tok === "r" ? 4 : 8;
      ev.set(s, Array.from({ length: n }, (_, k) => ({ midi: 60, steps: 1, vel: 0.35 + 0.5 * (k / (n - 1)), frac: k / n })));
    }
  }
  return ev;
}

// ---------------------------------------------------------------- layers → events
// Deterministic ±8 % velocity jitter (music.js uses Math.random): the same at every pass of a loop.
function jitter(...keys) {
  let h = 2166136261;
  for (const k of keys) { h ^= k + 0x9e3779b9; h = Math.imul(h, 16777619); h ^= h >>> 13; }
  return 1 + (((h >>> 0) / 4294967296) * 2 - 1) * 0.08;
}

const lerp = (r, f) => (r ? r[0] + (r[1] - r[0]) * f : 1);

function layerEvents(l, ctx) {
  const { chords, symbols, spb, total, where } = ctx;
  if (l.play === "chords") {
    const ev = new Map();
    const lo = 12 * (l.oct + 1) + 3;
    let held = null;
    chords.forEach((c, bar) => {
      if (held && symbols[bar - 1] === symbols[bar] && !l.restrike) { held.forEach((n) => (n.steps += spb)); return; }
      held = c.tones.map((t) => ({ midi: lo + ((c.root + t - lo) % 12 + 12) % 12, steps: spb, vel: 1 }));
      ev.set(bar * spb, held);
    });
    return ev;
  }
  if (l.play === "pattern") return sequence(tokens(l.pat), total, (tok, s) => degree(chords[Math.floor(s / spb)], tok, 12 * (l.oct + 1)));
  if (l.play === "notes") {
    const toks = tokens(l.notes);
    if (toks.length !== total) throw new Error(`${where} : la mélodie fait ${toks.length} pas au lieu de ${total}`);
    return sequence(toks, total, (tok) => tok.split("+").map((x) => noteToMidi(x) + (l.transpose || 0)));
  }
  if (l.play === "line") return line(l.line, spb, total, l.transpose || 0, where);
  if (l.play === "strum") return strum(l, chords, spb, total);
  if (l.play === "drums") return drums(l, total);
  throw new Error(`${where} : type de piste inconnu ${l.play}`);
}

// ---------------------------------------------------------------- a score of sections
/**
 * Returns { events: [{ t, dur, midi, vel, inst, pan, send, layer, section }], length (s), sections: [...] }.
 * Times start at 0 (the first step of the first section).
 */
export function compileScore(score, { reverb = 0.3 } = {}) {
  const events = [];
  const sections = [];
  let t0 = 0, bar0 = 0;
  score.sections.forEach((sec, si) => {
    const where = `${score.title || "partition"} § ${sec.name || si + 1}`;
    const spb = sec.beats * sec.sub;
    const symbols = tokens(sec.chords);
    const chords = symbols.map(parseChord);
    const total = chords.length * spb;
    // Step times, the tempo going linearly from bpm to bpm × rit over the section.
    const base = 60 / sec.bpm / sec.sub;
    const times = new Float64Array(total + 1);
    for (let s = 0; s < total; s++) times[s + 1] = times[s] + base / (1 + ((sec.rit ?? 1) - 1) * (s / total));
    const ctx = { chords, symbols, spb, total, where };
    (sec.layers || []).forEach((l, li) => {
      const ev = layerEvents(l, ctx);
      const send = l.send ?? score.reverb ?? reverb;
      for (const [s, notes] of ev) {
        const f = s / total;
        const swing = sec.swing && s % 2 ? sec.swing * (times[s + 1] - times[s]) : 0;
        notes.forEach((n, k) => {
          const end = Math.min(s + n.steps, total + 64);
          const span = (end <= total ? times[end] : times[total] + (end - total) * base) - times[s];
          const stepLen = times[s + 1] - times[s];
          let dur = l.ring ? 99 : span * (l.legato ?? 0.92);
          if (n.stac) dur = Math.min(dur, Math.max(stepLen * 0.5, 0.16)); // (staccato: short, but long enough to sound)
          const vel = (l.vol ?? 0.5) * n.vel * lerp(sec.dyn, f) * lerp(l.dyn, f) * jitter(si, li, s, k, Math.round(n.midi));
          const t = t0 + times[s] + swing + (n.delay || 0) + (n.frac || 0) * stepLen;
          const base = {
            midi: n.midi, inst: l.inst, pan: l.pan || 0, send, layer: `${si}:${li}`, section: si, lead: !!l.lead,
            bar: bar0 + Math.floor(s / spb), pos: s % spb, steps: n.steps, spb,
          };
          if (!l.trem) { events.push({ ...base, t, dur, vel }); return; }
          // `trem`: the note re-bowed `trem` times a second (a string tremolo), the bow a little uneven.
          const count = Math.max(1, Math.round(span * l.trem));
          for (let r = 0; r < count; r++) {
            events.push({ ...base, t: t + (r * span) / count, dur: (span / count) * 0.85, vel: vel * (r % 2 ? 0.86 : 1) * jitter(si, li, s, k, r + 7) });
          }
        });
      }
    });
    sections.push({ name: sec.name || String(si + 1), start: t0, end: t0 + times[total], bpm: sec.bpm, beats: sec.beats, sub: sec.sub, chords: symbols, key: sec.key, bars: chords.length });
    t0 += times[total];
    bar0 += chords.length;
  });
  events.sort((a, b) => a.t - b.t);
  return { events, length: t0, sections };
}

// ---------------------------------------------------------------- an original theme (music.js)
/** Passes [first, first + count) of a theme of musicThemes.js, as the Phaser player plays them. */
export function compileTheme(id, def, first = 1, count = 1) {
  const spb = def.beats * def.sub;
  const symbols = tokens(def.chords);
  const chords = symbols.map(parseChord);
  const total = chords.length * spb;
  const stepDur = 60 / def.bpm / def.sub;
  const ctx = { chords, symbols, spb, total, where: id };
  const layers = def.layers.map((l, li) => {
    let variants;
    if (l.play === "gen") {
      const seed = (l.seed ?? 7) * 7919 + id.length;
      variants = [generate(def, l, chords, spb, seed), generate(def, l, chords, spb, seed + 1)];
    } else variants = [layerEvents(l, ctx)];
    return { ...l, li, variants };
  });
  const events = [];
  for (let pass = first; pass < first + count; pass++) {
    for (let s = 0; s < total; s++) {
      const swing = def.swing && s % 2 ? def.swing * stepDur : 0;
      const t = ((pass - first) * total + s) * stepDur + swing;
      for (const l of layers) {
        if (l.from && pass < l.from) continue;
        if (l.every && !l.every[pass % l.every.length]) continue;
        if (l.ride) continue;
        const notes = l.variants[pass % l.variants.length].get(s);
        if (!notes) continue;
        notes.forEach((n, k) => {
          events.push({
            t, dur: l.ring ? 99 : n.steps * stepDur * (l.legato ?? 0.92), midi: n.midi,
            vel: (l.vol ?? 0.5) * n.vel * jitter(pass, l.li, s, k), inst: l.inst, pan: l.pan || 0,
            send: def.reverb ?? 0.3, layer: `0:${l.li}`, section: 0, lead: l.play === "notes" || l.play === "gen",
            bar: (pass - first) * chords.length + Math.floor(s / spb), pos: s % spb, steps: n.steps, spb,
          });
        });
      }
    }
  }
  events.sort((a, b) => a.t - b.t);
  return { events, length: count * total * stepDur, sections: [{ name: id, start: 0, end: count * total * stepDur, bpm: def.bpm, beats: def.beats, sub: def.sub, chords: symbols, bars: chords.length }] };
}
