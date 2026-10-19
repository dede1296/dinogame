// Renders a theme or a score in the browser with an OfflineAudioContext: the instruments of the
// Phaser version (synth/audio/instruments.js, the same Web Audio graph as synth/audio/music.js),
// scheduled all at once instead of live. Loaded by render.mjs in headless Edge.
import { playNote, warm, isDrum, noiseBuffer } from "../synth/audio/instruments.js";
import { makeReverb } from "../synth/audio/mixer.js";
import "./instruments-plus.js";
import { compileScore, compileTheme } from "./compile.js";

const SR = 48000;
const LEAD_S = 0.1;
// music.js: the "Musique" volume (0.42 by default) × MUSIC_TRIM (0.5), then its gentle limiter.
const PHASER_BUS = 0.42 * 0.5;

// A seeded Math.random: every pass of a loop draws the same numbers (pluck noise, breath…).
function seeded(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// The Phaser bus: out → duck → bus (0.21) → DynamicsCompressor → destination, reverb send → duck.
function phaserGraph(ctx, def) {
  const bus = ctx.createGain();
  bus.gain.value = PHASER_BUS;
  const limiter = ctx.createDynamicsCompressor();
  limiter.threshold.value = -8;
  limiter.knee.value = 6;
  limiter.ratio.value = 8;
  limiter.attack.value = 0.005;
  limiter.release.value = 0.2;
  bus.connect(limiter).connect(ctx.destination);
  const duck = ctx.createGain();
  duck.connect(bus);
  const reverb = makeReverb(ctx, 2.8, 0.55);
  reverb.connect(duck);
  const out = ctx.createGain();
  out.gain.value = def.gain ?? 1;
  out.connect(duck);
  const send = ctx.createGain();
  send.gain.value = def.reverb ?? 0.3;
  out.connect(send).connect(reverb);
  return () => out;
}

// A score: no bus limiter (the level is set afterwards, render.mjs), one reverb, a send per level.
function scoreGraph(ctx, score) {
  const master = ctx.createGain();
  master.connect(ctx.destination);
  const reverb = makeReverb(ctx, score.reverbSeconds ?? 2.8, score.reverbDamp ?? 0.55);
  reverb.connect(master);
  const outs = new Map();
  return (send) => {
    if (!outs.has(send)) {
      const out = ctx.createGain();
      out.connect(master);
      const g = ctx.createGain();
      g.gain.value = send;
      out.connect(g).connect(reverb);
      outs.set(send, out);
    }
    return outs.get(send);
  };
}

/**
 * spec: { kind: "theme", name, first, count, bus } | { kind: "score", name }.
 * Returns where the useful part is: { sampleRate, frames, start, length, loop }.
 * The audio stays in window.__out (read by chunks, see readChunk).
 */
export async function render(spec) {
  const seed = spec.seed ?? 20261019;
  Math.random = seeded(seed);
  let comp, loop, tail, outFor, ctx;
  if (spec.kind === "theme") {
    const { THEMES } = await import("../synth/data/musicThemes.js");
    const def = THEMES[spec.name];
    if (!def) throw new Error(`Thème inconnu : ${spec.name}`);
    comp = compileTheme(spec.name, def, spec.first ?? 1, spec.count ?? 1);
    loop = spec.loop ?? true;
    tail = spec.tail ?? 2.5;
    const frames = Math.ceil((LEAD_S + comp.length * (loop ? spec.cycles ?? 2 : 1) + (loop ? 0 : tail)) * SR) + 256;
    ctx = new OfflineAudioContext(2, frames, SR);
    outFor = spec.bus === false ? scoreGraph(ctx, { reverbSeconds: 2.8 }) : phaserGraph(ctx, def);
  } else {
    const score = (await import(`../scores/${spec.name}.js`)).default;
    comp = compileScore(score);
    loop = !!score.loop;
    tail = score.tail ?? 4;
    const frames = Math.ceil((LEAD_S + comp.length * (loop ? spec.cycles ?? 2 : 1) + (loop ? 0 : tail)) * SR) + 256;
    ctx = new OfflineAudioContext(2, frames, SR);
    outFor = scoreGraph(ctx, score);
  }
  warm(ctx, [...new Set(comp.events.map((e) => e.inst))]);
  noiseBuffer(ctx); // (made now, not at the first flute note: every pass then draws the same numbers)
  // A loop lasts a whole number of render quanta (128 frames): every pass then meets the browser's
  // block grid at the same places, and plays exactly the same samples (the tempo moves by < 0.003 %).
  const exact = comp.length * SR;
  const cycleFrames = loop ? Math.round(exact / 128) * 128 : Math.round(exact);
  const scale = cycleFrames / exact;
  // A loop is played twice and the second pass kept: it begins with the tails of the first (seamless).
  const cycles = loop ? spec.cycles ?? 2 : 1;
  // Times on whole frames + 1/4 (and durations on whole frames): every pass of a loop then lands on
  // exactly the same sub-sample positions, whatever the rounding of the browser.
  const leadFrames = Math.round(LEAD_S * SR);
  const notes = [];
  for (let c = 0; c < cycles; c++) {
    for (const e of comp.events) {
      const at = (leadFrames + c * cycleFrames + Math.round(e.t * SR * scale) + 0.25) / SR;
      notes.push({ c, at, dur: e.dur >= 90 ? e.dur : Math.max(1, Math.round(e.dur * SR * scale)) / SR, e });
    }
  }
  notes.sort((a, b) => a.at - b.at);
  // The notes are made just in time (the render pauses every SLICE_S) and unplugged once silent:
  // a graph of thousands of voices would slow the rendering down to a crawl. Each pass reseeds Math.random.
  let next = 0, cycle = -1;
  const live = [];
  const scheduleUntil = (until, now) => {
    for (let i = live.length - 1; i >= 0; i--) if (live[i].end < now) { live[i].node.disconnect(); live.splice(i, 1); }
    while (next < notes.length && notes[next].at < until) {
      const { c, at, dur, e } = notes[next++];
      if (c !== cycle) { cycle = c; Math.random = seeded(seed + 1); }
      const node = ctx.createGain();
      node.connect(outFor(e.send));
      playNote(ctx, node, e.inst, isDrum(e.inst) ? 60 : e.midi, at, dur, e.vel, e.pan);
      live.push({ node, end: at + (dur >= 90 ? 15 : dur + 4) });
    }
  };
  const SLICE_S = 1;
  const quantum = 128 / SR;
  scheduleUntil(SLICE_S, 0);
  for (let t = SLICE_S; t < ctx.length / SR - quantum; t += SLICE_S) {
    const at = Math.floor(t / quantum) * quantum;
    const until = t + SLICE_S;
    ctx.suspend(at).then(() => { scheduleUntil(until, at); ctx.resume(); });
  }
  const buf = await ctx.startRendering();
  window.__out = [buf.getChannelData(0), buf.getChannelData(1)];
  // A loop file starts half a step before the downbeat of its first bar (as a pickup): the encoder
  // then meets no attack at its very first sample, and the seam falls between two notes.
  const last = comp.sections[comp.sections.length - 1];
  const rotation = loop ? Math.round((60 / last.bpm / last.sub / 2) * SR * scale) : 0;
  const loopStart = leadFrames + cycleFrames - rotation;
  let start = loop ? loopStart : leadFrames;
  let length = loop ? cycleFrames : Math.min(buf.length - start, Math.round((comp.length + tail) * SR));
  if (spec.full) { start = 0; length = buf.length; } // (debugging: the whole render)
  return { sampleRate: SR, frames: buf.length, start, length, loop: loop && !spec.full, cycleFrames, loopStart, rotationSeconds: +(rotation / SR).toFixed(4), seconds: comp.length, events: comp.events.length, sections: comp.sections.map((s) => ({ name: s.name, start: +s.start.toFixed(2), end: +s.end.toFixed(2) })) };
}

/** A chunk of channel `ch` of the last render, as base64 float32. */
export function readChunk(ch, from, n) {
  const f32 = window.__out[ch].subarray(from, from + n);
  const bytes = new Uint8Array(f32.buffer, f32.byteOffset, f32.byteLength);
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}
