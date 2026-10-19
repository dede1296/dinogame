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
