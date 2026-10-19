// A few more instruments for the scores, made with the same recipes as synth/audio/instruments.js
// (live oscillators through a filter, or decaying sine partials rendered once): soft horns and a
// bassoon (asked for by docs/cinematiques.md), tremolo strings, low strings and a pitched timpani.
// Importing this module adds them to the tables of instruments.js; the original ones are untouched.
import { SAMPLED, LIVE } from "../synth/audio/instruments.js";

const TAU = Math.PI * 2;

// Sum of decaying sine partials (same as instruments.js `additive`), with a soft felt thump.
function struck(rate, hz, seconds, partials, thump) {
  const out = new Float32Array(Math.floor(rate * seconds));
  for (const [ratio, amp, decay] of partials) {
    const f = hz * ratio;
    if (f > rate / 2.2) continue;
    const w = TAU * f / rate, k = Math.exp(-1 / (decay * rate));
    let env = amp;
    for (let n = 0; n < out.length; n++) { out[n] += Math.sin(w * n) * env; env *= k; }
  }
  const a = Math.floor(0.004 * rate);
  for (let n = 0; n < a; n++) out[n] *= n / a;
  let lp = 0;
  for (let n = 0; n < thump * rate; n++) { lp += 0.08 * (Math.random() * 2 - 1 - lp); out[n] += lp * 2.2 * (1 - n / (thump * rate)); }
  return { data: out, hz };
}

Object.assign(LIVE, {
  // Soft french horns: round, slow to speak, little vibrato.
  horn: { waves: [["sawtooth", -5, 0.45], ["sawtooth", 5, 0.45], ["triangle", 0, 0.5]], cutoff: 760, q: 0.6, filterEnv: 1.7, attack: 0.13, release: 0.45, vib: { rate: 4.6, depth: 4, delay: 0.5 }, gain: 0.46 },
  // A bassoon: reedy and nasal in the low register (a darker "reed").
  bassoon: { waves: [["sawtooth", -3, 0.45], ["square", 3, 0.3]], cutoff: 980, q: 1.6, attack: 0.025, release: 0.09, vib: { rate: 5.4, depth: 5, delay: 0.25 }, gain: 0.46 },
  // Strings that speak at once: repeated quickly, a tremolo.
  tremolo: { waves: [["sawtooth", -10, 0.4], ["sawtooth", 0, 0.4], ["sawtooth", 11, 0.4]], cutoff: 1900, q: 0.5, attack: 0.018, release: 0.06, gain: 0.26 },
  // Cellos and basses: the strings, darker and slower.
  cello: { waves: [["sawtooth", -7, 0.45], ["sawtooth", 6, 0.45]], cutoff: 1250, q: 0.6, attack: 0.22, release: 0.8, vib: { rate: 5, depth: 7, delay: 0.35 }, gain: 0.34 },
  // A slow breath: swells in over 2 s, fades over 2.5 s (the crater).
  swell: { waves: [["sawtooth", -7, 0.4], ["sawtooth", 7, 0.4], ["triangle", 0, 0.5]], cutoff: 950, q: 0.4, attack: 2.2, release: 2.5, gain: 0.32 },
});

Object.assign(SAMPLED, {
  // A pitched timpani (plays the bass note), soft mallets.
  timpani: { seconds: 2.4, gain: 0.95, render: (r, hz, s) => struck(r, hz, s, [[1, 1, 0.75], [1.5, 0.45, 0.45], [1.98, 0.28, 0.35], [2.44, 0.14, 0.22], [2.9, 0.07, 0.15]], 0.03) },
});

// ---------------------------------------------------------------- added on 19/10 (second batch)
// Five more for nids_geants, arche_du_vent, forges_ombre, souverain, jetee: the same recipes again
// (oscillators through a filter or formants; decaying partials; filtered noise as the flute's breath).

/** RBJ band-pass (0 dB at its centre) as a tiny stateful function. */
function bandpass(rate, f, q) {
  const w = TAU * f / rate, al = Math.sin(w) / (2 * q), c = Math.cos(w), a0 = 1 + al;
  const b0 = al / a0, b2 = -al / a0, a1 = -2 * c / a0, a2 = (1 - al) / a0;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  return (x) => { const y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; return y; };
}

const rmsOf = (a, from, to) => { let e = 0; for (let i = from; i < to; i++) e += a[i] * a[i]; return Math.sqrt(e / Math.max(1, to - from)) || 1; };

/**
 * The wind that sings: white noise through a narrow resonance on the note (two in a row), a softer one
 * an octave up and a broad hiss; it swells in over 1.6 s, gusts a little, dies away by the end.
 */
function windTone(rate, hz, seconds) {
  const n = Math.floor(rate * seconds);
  const tone = new Float32Array(n), octave = new Float32Array(n), hiss = new Float32Array(n);
  const r1 = bandpass(rate, hz, 24), r2 = bandpass(rate, hz, 24), r3 = bandpass(rate, Math.min(2 * hz, rate / 3), 10);
  const r4 = bandpass(rate, Math.min(3 * hz, rate / 3), 1.1);
  for (let i = 0; i < n; i++) {
    const x = Math.random() * 2 - 1;
    tone[i] = r2(r1(x)); octave[i] = r3(x); hiss[i] = r4(x);
  }
  const a = Math.floor(0.5 * rate), b = Math.floor(1.5 * rate);
  const kt = 1 / rmsOf(tone, a, b), ko = 0.35 / rmsOf(octave, a, b), kh = 0.42 / rmsOf(hiss, a, b);
  const out = new Float32Array(n);
  const att = 1.6, rel = seconds - att;
  for (let i = 0; i < n; i++) {
    const t = i / rate;
    const env = t < att ? Math.sin((0.5 * Math.PI * t) / att) ** 2 : Math.cos(0.5 * Math.PI * Math.min(1, (t - att) / rel)) ** 2;
    const gust = 0.82 + 0.18 * Math.sin(TAU * 0.37 * t + 1.3) * Math.sin(TAU * 0.23 * t + 0.4);
    out[i] = 0.22 * (tone[i] * kt + octave[i] * ko + hiss[i] * kh) * env * gust;
  }
  return { data: out, hz };
}

/** A struck metal bar (an anvil, a little hammer): inharmonic partials and a bright click. */
function metal(rate, hz, seconds, partials, click) {
  const out = new Float32Array(Math.floor(rate * seconds));
  for (const [ratio, amp, decay] of partials) {
    const f = hz * ratio;
    if (f > rate / 2.2) continue;
    const w = TAU * f / rate, k = Math.exp(-1 / (decay * rate));
    let env = amp;
    for (let i = 0; i < out.length; i++) { out[i] += Math.sin(w * i) * env; env *= k; }
  }
  const a = Math.floor(0.001 * rate);
  for (let i = 0; i < a; i++) out[i] *= i / a;
  let prev = 0;
  for (let i = 0; i < click * rate; i++) { const x = Math.random() * 2 - 1; out[i] += (x - prev) * 0.2 * (1 - i / (click * rate)); prev = x; }
  return { data: out, hz };
}

Object.assign(SAMPLED, {
  // The wind in the arch and the wings: a pitched gust (lasts its whole sample: play it with `ring`).
  wind: { seconds: 5.5, gain: 0.9, render: (r, hz, s) => windTone(r, hz, s) },
  // An anvil (small, bright, rings a little): the forges' hammers, in tune.
  anvil: { seconds: 1.6, gain: 0.32, render: (r, hz, s) => metal(r, hz, s, [[1, 1, 0.55], [2.76, 0.55, 0.32], [5.4, 0.3, 0.14], [8.93, 0.16, 0.06], [3.9, 0.2, 0.2]], 0.004) },
});

Object.assign(LIVE, {
  // A musette accordion: three reeds, the outer two tuned apart (the beating shimmer), no vibrato.
  accordion: { waves: [["sawtooth", -14, 0.3], ["square", 0, 0.2], ["sawtooth", 13, 0.3]], cutoff: 2500, q: 1.4, filterEnv: 1.25, attack: 0.03, release: 0.08, sustain: 0.88, gain: 0.42 },
  // A solo fiddle: two close saws through the body's resonances (formants, as the choir), a wide vibrato.
  fiddle: { waves: [["sawtooth", -3, 0.5], ["sawtooth", 3, 0.5]], formants: [[480, 2.2, 0.7], [1150, 2.8, 1], [2700, 3.5, 0.75], [4300, 4, 0.3]], attack: 0.07, release: 0.22, vib: { rate: 5.7, depth: 15, delay: 0.16 }, gain: 1.0 },
  // A tuba: round and low, a little blat at the start of each note.
  tuba: { waves: [["sawtooth", 0, 0.5], ["triangle", 0, 0.7]], cutoff: 520, q: 0.9, filterEnv: 1.8, attack: 0.04, release: 0.12, sustain: 0.85, vib: { rate: 4.5, depth: 3, delay: 0.4 }, gain: 0.3 },
});
