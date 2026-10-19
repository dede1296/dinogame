// Music: one theme at a time (data/musicThemes.js), played live by a small sequencer.
// Themes cross-fade when the place or the situation changes; jingles play once.
// It follows the "Musique" volume (Réglages), separate from the sound effects.

import { audioContext } from "./sounds.js";
import { playNote, warm, isDrum } from "./instruments.js";
import { storedVolume, makeReverb } from "./mixer.js";
import { THEMES } from "../data/musicThemes.js";

const volume = storedVolume("dino-music-volume", 0.42);
const LOOKAHEAD_S = 0.2;
const TICK_MS = 50;
const DUCKED = 0.35; // music level under a recorded voice line
// The music sits under the rest of the game: the "Musique" setting is scaled by this.
const MUSIC_TRIM = 0.5;
const RIDE_TEMPO = 1.12; // faster while riding a dino

let bus = null, duck = null, reverb = null;
let current = null; // the playing Player
let wanted = null; // theme id waiting for the audio to be unlocked
let intensity = 0;

function outputs(ctx) {
  if (!bus) {
    bus = ctx.createGain();
    bus.gain.value = volume.get() * MUSIC_TRIM;
    // A gentle limiter: loud passages (war drums, brass) never clip.
    const limiter = ctx.createDynamicsCompressor();
    limiter.threshold.value = -8;
    limiter.knee.value = 6;
    limiter.ratio.value = 8;
    limiter.attack.value = 0.005;
    limiter.release.value = 0.2;
    bus.connect(limiter).connect(ctx.destination);
    duck = ctx.createGain();
    duck.connect(bus);
    reverb = makeReverb(ctx, 2.8, 0.55);
    reverb.connect(duck);
    // Start the waiting theme as soon as the first touch unlocks the audio.
    ctx.addEventListener?.("statechange", () => { if (ctx.state === "running" && wanted) { const w = wanted; wanted = null; music(w.id, w.opts); } });
  }
  return { dry: duck, wet: reverb };
}

// ---------------------------------------------------------------- notation
// Notes: "C5", "F#4", "Bb3". Chords: "Am", "G7", "Cmaj7", "Dsus4", "E5" (power chord)…
const PITCH = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
const QUALITY = {
  "": [0, 4, 7], m: [0, 3, 7], 7: [0, 4, 7, 10], m7: [0, 3, 7, 10], maj7: [0, 4, 7, 11], m9: [0, 3, 7, 10, 14],
  sus2: [0, 2, 7], sus4: [0, 5, 7], dim: [0, 3, 6], aug: [0, 4, 8], add9: [0, 4, 7, 14], 5: [0, 7], 6: [0, 4, 7, 9], m6: [0, 3, 7, 9],
};

export function noteToMidi(tok) {
  const m = tok.match(/^([A-G])([#b]?)(-?\d)$/);
  if (!m) throw new Error(`Note inconnue : ${tok}`);
  return 12 * (+m[3] + 1) + PITCH[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0);
}

export function parseChord(sym) {
  const m = sym.match(/^([A-G])([#b]?)(.*)$/);
  if (!m || !(m[3] in QUALITY)) throw new Error(`Accord inconnu : ${sym}`);
  const root = PITCH[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0);
  return { root: (root + 12) % 12, tones: QUALITY[m[3]] };
}

const tokens = (s) => s.split(/\s+/).filter((t) => t && t !== "|");

// A chord degree ("1", "3", "5", "7", "8", "10", "12", "L5" = fifth below) as a MIDI note.
function degree(chord, tok, base) {
  const low = tok.startsWith("L");
  const n = +tok.replace("L", "");
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
    if (tok === "-") { if (last) last.steps++; continue; }
    last = null;
    if (tok === ".") continue;
    const midi = noteOf(tok, s);
    if (midi == null) continue;
    last = { midi, steps: 1, vel: 1 };
    ev.set(s, [last]);
  }
  return ev;
}

// ---------------------------------------------------------------- generated melodies
// For themes written as recipes (the regions of later chapters): a seeded melody that
// follows the chords, so each theme keeps the same tune every time it loops.
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
    // Every other bar echoes the rhythm of the one before: sounds composed, not random.
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
        // Strong beats land on a chord tone, the closest to the previous note.
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

// ---------------------------------------------------------------- compiling
function compile(id) {
  const def = THEMES[id];
  if (!def) throw new Error(`Musique inconnue : ${id}`);
  const spb = def.beats * def.sub;
  const symbols = tokens(def.chords);
  const chords = symbols.map(parseChord);
  const total = chords.length * spb;
  const layers = def.layers.map((l, i) => {
    let variants;
    if (l.play === "chords") {
      // One held chord per bar; a repeated chord is held on (unless `restrike`).
      const ev = new Map();
      const lo = 12 * (l.oct + 1) + 3;
      let held = null;
      chords.forEach((c, bar) => {
        if (held && symbols[bar - 1] === symbols[bar] && !l.restrike) { held.forEach((n) => (n.steps += spb)); return; }
        held = c.tones.map((t) => ({ midi: lo + ((c.root + t - lo) % 12 + 12) % 12, steps: spb, vel: 1 }));
        ev.set(bar * spb, held);
      });
      variants = [ev];
    } else if (l.play === "pattern") {
      const toks = tokens(l.pat);
      variants = [sequence(toks, total, (tok, s) => degree(chords[Math.floor(s / spb)], tok, 12 * (l.oct + 1)))];
    } else if (l.play === "notes") {
      const toks = tokens(l.notes);
      if (toks.length !== total) throw new Error(`${id} : la mélodie ${i} fait ${toks.length} pas au lieu de ${total}`);
      variants = [sequence(toks, total, (tok) => noteToMidi(tok) + (l.transpose || 0))];
    } else if (l.play === "drums") {
      const ev = new Map();
      const toks = tokens(l.pat);
      for (let s = 0; s < total; s++) {
        const tok = toks[s % toks.length];
        if (tok === "x" || tok === "o") ev.set(s, [{ midi: 60, steps: 1, vel: tok === "x" ? 1 : 0.55 }]);
      }
      variants = [ev];
    } else if (l.play === "gen") {
      if (!def.scale) throw new Error(`${id} : une mélodie générée demande key et scale`);
      const seed = (l.seed ?? 7) * 7919 + id.length;
      variants = [generate(def, l, chords, spb, seed), generate(def, l, chords, spb, seed + 1)];
    } else throw new Error(`${id} : type de piste inconnu ${l.play}`);
    return { ...l, variants };
  });
  return { id, def, spb, total, layers };
}

const compiled = new Map();
const themeOf = (id) => { if (!compiled.has(id)) compiled.set(id, compile(id)); return compiled.get(id); };

// ---------------------------------------------------------------- player
class Player {
  constructor(ctx, theme, { once = false, onEnd = null } = {}) {
    this.ctx = ctx;
    this.theme = theme;
    this.once = once;
    this.onEnd = onEnd;
    const { dry, wet } = outputs(ctx);
    this.out = ctx.createGain();
    this.out.gain.value = 0;
    this.out.connect(dry);
    const send = ctx.createGain();
    send.gain.value = theme.def.reverb ?? 0.3;
    this.out.connect(send).connect(wet);
    warm(ctx, theme.layers.map((l) => l.inst));
    this.step = 0;
    this.next = ctx.currentTime + 0.08;
    this.timer = setInterval(() => this.schedule(), TICK_MS);
  }

  fadeIn(s) {
    const g = this.out.gain, t = this.ctx.currentTime;
    g.cancelScheduledValues(t);
    g.setValueAtTime(g.value, t);
    g.linearRampToValueAtTime(this.theme.def.gain ?? 1, t + Math.max(0.02, s));
    this.schedule();
  }

  stop(s) {
    clearInterval(this.timer);
    const g = this.out.gain, t = this.ctx.currentTime;
    g.cancelScheduledValues(t);
    g.setValueAtTime(g.value, t);
    g.linearRampToValueAtTime(0, t + Math.max(0.02, s));
    setTimeout(() => this.out.disconnect(), (s + LOOKAHEAD_S + 3) * 1000);
  }

  schedule() {
    const { def, spb, total, layers } = this.theme;
    const stepDur = 60 / def.bpm / def.sub / (intensity ? RIDE_TEMPO : 1);
    while (this.next < this.ctx.currentTime + LOOKAHEAD_S) {
      if (this.once && this.step >= total) {
        clearInterval(this.timer);
        setTimeout(() => this.onEnd?.(), (this.next - this.ctx.currentTime) * 1000 + 600);
        return;
      }
      const pass = Math.floor(this.step / total), s = this.step % total;
      const swing = def.swing && s % 2 ? def.swing * stepDur : 0;
      for (const l of layers) this.playLayer(l, pass, s, this.next + swing, stepDur);
      this.step++;
      this.next += stepDur;
    }
  }

  playLayer(l, pass, s, t, stepDur) {
    if (l.from && pass < l.from) return;
    if (l.every && !l.every[pass % l.every.length]) return;
    if (l.ride && !intensity) return;
    const notes = l.variants[pass % l.variants.length].get(s);
    if (!notes) return;
    if (l.prob != null && Math.random() > l.prob) return;
    for (const n of notes) {
      const dur = l.ring ? 99 : n.steps * stepDur * (l.legato ?? 0.92);
      const vel = (l.vol ?? 0.5) * n.vel * (1 + (Math.random() * 2 - 1) * 0.08);
      playNote(this.ctx, this.out, l.inst, isDrum(l.inst) ? 60 : n.midi, t, dur, vel, l.pan || 0);
    }
  }
}

// ---------------------------------------------------------------- public
export const getMusicVolume = () => volume.get();

export function setMusicVolume(v) {
  const val = volume.set(v);
  if (bus) bus.gain.value = val * MUSIC_TRIM;
}

/** The theme playing (or waiting to play), for the tests. */
export const currentMusic = () => wanted?.id ?? current?.theme.id ?? null;

/** Cross-fades to theme `id` (nothing if it is already playing). `null` fades out. */
export function music(id, { fade = 1.5 } = {}) {
  if (!id) return stopMusic(fade);
  if (current?.theme.id === id && !current.once) return;
  const ctx = audioContext();
  if (!ctx) return;
  if (ctx.state !== "running") { outputs(ctx); current?.stop(0.1); current = null; wanted = { id, opts: { fade } }; return; }
  wanted = null;
  current?.stop(fade);
  current = new Player(ctx, themeOf(id));
  current.fadeIn(fade * 0.7);
}

export function stopMusic(fade = 1) {
  wanted = null;
  current?.stop(fade);
  current = null;
}

/**
 * Plays a short piece once (victory, capture…) instead of the current theme.
 * With `resume`, the theme that was playing comes back afterwards.
 */
export function jingle(id, { resume = false } = {}) {
  const ctx = audioContext();
  if (!ctx || ctx.state !== "running") return;
  const before = current && !current.once ? current.theme.id : null;
  current?.stop(0.25);
  const p = new Player(ctx, themeOf(id), {
    once: true,
    onEnd: () => {
      if (current !== p) return;
      p.stop(0.5);
      current = null;
      if (resume && before) music(before, { fade: 2 });
    },
  });
  current = p;
  p.fadeIn(0.02);
}

/** 1 while riding a dino: faster, with the extra "ride" layers. */
export function setIntensity(n) { intensity = n; }

/** Lowers the music under a recorded voice line. */
export function duckMusic(on) {
  const ctx = audioContext();
  if (!ctx || !duck) return;
  duck.gain.setTargetAtTime(on ? DUCKED : 1, ctx.currentTime, on ? 0.15 : 0.6);
}

/** Checks every theme (for the tests): throws on a bad note, chord or length. */
export function validateThemes() {
  return Object.keys(THEMES).map((id) => { compiled.delete(id); return themeOf(id).id; });
}
