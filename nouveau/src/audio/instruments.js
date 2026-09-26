// Instruments of the music (music.js), all synthesized: no audio file to download.
// - Plucked and struck sounds (harp, kalimba, piano, marimba, music box, drums…) are
//   rendered once into buffers, then played at any pitch by resampling.
// - Held sounds (pad, strings, flute, reed, brass, choir, leads, basses) are live oscillators.

export const midiToHz = (m) => 440 * 2 ** ((m - 69) / 12);

// ---------------------------------------------------------------- rendered buffers
const TAU = Math.PI * 2;

// Karplus-Strong plucked string. Returns the buffer data and its exact pitch.
function pluck(rate, hz, seconds, { bright = 0.5, sustain = 0.996 }) {
  const period = Math.max(2, Math.round(rate / hz));
  const line = new Float32Array(period);
  let lp = 0;
  for (let i = 0; i < period; i++) { lp += bright * (Math.random() * 2 - 1 - lp); line[i] = lp; }
  const out = new Float32Array(Math.floor(rate * seconds));
  let i = 0;
  for (let n = 0; n < out.length; n++) {
    const next = (i + 1) % period;
    const v = line[i];
    line[i] = sustain * 0.5 * (v + line[next]);
    out[n] = v;
    i = next;
  }
  return { data: out, hz: rate / period };
}

// Sum of decaying sine partials: [ratio, amplitude, decay (s)].
function additive(rate, hz, seconds, partials, { attack = 0.003, click = 0 } = {}) {
  const out = new Float32Array(Math.floor(rate * seconds));
  for (const [ratio, amp, decay] of partials) {
    const f = hz * ratio;
    if (f > rate / 2.2) continue;
    const w = TAU * f / rate, k = Math.exp(-1 / (decay * rate));
    let env = amp;
    for (let n = 0; n < out.length; n++) { out[n] += Math.sin(w * n) * env; env *= k; }
  }
  const a = Math.floor(attack * rate);
  for (let n = 0; n < a; n++) out[n] *= n / a;
  for (let n = 0; n < click * rate; n++) out[n] += (Math.random() * 2 - 1) * 0.3 * (1 - n / (click * rate));
  return { data: out, hz };
}

// A decaying sound whose pitch falls (drums).
function sweep(rate, seconds, { from, to, fall, decay, noise = 0, noiseDecay = 0.05, hp = false }) {
  const out = new Float32Array(Math.floor(rate * seconds));
  let phase = 0, prev = 0;
  for (let n = 0; n < out.length; n++) {
    const t = n / rate;
    const f = to + (from - to) * Math.exp(-t / fall);
    phase += TAU * f / rate;
    let v = from ? Math.sin(phase) * Math.exp(-t / decay) : 0;
    if (noise) {
      let r = Math.random() * 2 - 1;
      if (hp) { const d = r - prev; prev = r; r = d; }
      v += r * noise * Math.exp(-t / noiseDecay);
    }
    out[n] = v;
  }
  return { data: out, hz: 0 };
}

// name -> { render(rate, hz) or oneShot(rate), seconds, gain }
const SAMPLED = {
  harp: { seconds: 2.6, gain: 0.9, render: (r, hz, s) => pluck(r, hz, s, { bright: 0.45, sustain: 0.997 }) },
  guitar: { seconds: 2.0, gain: 0.9, render: (r, hz, s) => pluck(r, hz, s, { bright: 0.3, sustain: 0.995 }) },
  pizz: { seconds: 0.9, gain: 1.0, render: (r, hz, s) => pluck(r, hz, s, { bright: 0.22, sustain: 0.985 }) },
  kalimba: { seconds: 1.8, gain: 0.8, render: (r, hz, s) => additive(r, hz, s, [[1, 1, 0.55], [3.02, 0.18, 0.08], [5.4, 0.1, 0.03]], { click: 0.004 }) },
  piano: { seconds: 3.0, gain: 0.6, render: (r, hz, s) => additive(r, hz, s, [[1, 1, 1.1], [2.001, 0.45, 0.7], [3.003, 0.22, 0.45], [4.006, 0.12, 0.3], [5.01, 0.06, 0.2], [6.02, 0.03, 0.15]], { attack: 0.004, click: 0.003 }) },
  marimba: { seconds: 1.2, gain: 0.9, render: (r, hz, s) => additive(r, hz, s, [[1, 1, 0.38], [3.93, 0.3, 0.07], [9.2, 0.08, 0.02]], { attack: 0.002, click: 0.003 }) },
  musicbox: { seconds: 2.4, gain: 0.55, render: (r, hz, s) => additive(r, hz, s, [[1, 1, 0.9], [2.0, 0.25, 0.35], [3.0, 0.12, 0.15], [5.2, 0.08, 0.05]], { attack: 0.001 }) },
  bell: { seconds: 4.0, gain: 0.45, render: (r, hz, s) => additive(r, hz, s, [[1, 1, 1.8], [2.0, 0.5, 1.2], [2.76, 0.35, 0.9], [5.4, 0.18, 0.5], [8.93, 0.08, 0.25]], { attack: 0.002 }) },
};

const DRUMS = {
  kick: { seconds: 0.45, gain: 1.1, render: (r, s) => sweep(r, s, { from: 160, to: 46, fall: 0.03, decay: 0.16, noise: 0.25, noiseDecay: 0.005 }) },
  snare: { seconds: 0.3, gain: 0.55, render: (r, s) => sweep(r, s, { from: 210, to: 180, fall: 0.02, decay: 0.05, noise: 0.8, noiseDecay: 0.07, hp: true }) },
  hat: { seconds: 0.08, gain: 0.22, render: (r, s) => sweep(r, s, { from: 0, to: 0, fall: 1, decay: 1, noise: 1, noiseDecay: 0.018, hp: true }) },
  shaker: { seconds: 0.12, gain: 0.16, render: (r, s) => { const b = sweep(r, s, { from: 0, to: 0, fall: 1, decay: 1, noise: 1, noiseDecay: 0.035, hp: true }); for (let n = 0; n < 0.015 * r; n++) b.data[n] *= n / (0.015 * r); return b; } },
  tom: { seconds: 0.5, gain: 0.8, render: (r, s) => sweep(r, s, { from: 150, to: 88, fall: 0.06, decay: 0.2, noise: 0.1, noiseDecay: 0.01 }) },
  taiko: { seconds: 1.1, gain: 1.1, render: (r, s) => sweep(r, s, { from: 95, to: 52, fall: 0.08, decay: 0.35, noise: 0.35, noiseDecay: 0.02 }) },
  block: { seconds: 0.12, gain: 0.35, render: (r, s) => additive(r, 880, s, [[1, 1, 0.025], [1.72, 0.6, 0.018]], { attack: 0.0005 }) },
  triangle: { seconds: 1.5, gain: 0.12, render: (r, s) => additive(r, 2400, s, [[1, 1, 0.6], [2.76, 0.4, 0.4]], { attack: 0.0005 }) },
};

const ROOTS = [48, 60, 72, 84]; // each note uses the rendered pitch closest to it
const cache = new Map();

function sampleFor(ctx, name, midi) {
  const root = ROOTS.reduce((a, b) => (Math.abs(b - midi) < Math.abs(a - midi) ? b : a));
  const key = `${name}:${root}`;
  if (!cache.has(key)) {
    const def = SAMPLED[name];
    const { data, hz } = def.render(ctx.sampleRate, midiToHz(root), def.seconds);
    cache.set(key, toBuffer(ctx, data, hz));
  }
  return cache.get(key);
}

function drumFor(ctx, name) {
  if (!cache.has(name)) {
    const def = DRUMS[name];
    cache.set(name, toBuffer(ctx, def.render(ctx.sampleRate, def.seconds).data, 0));
  }
  return cache.get(name);
}

function toBuffer(ctx, data, hz) {
  const buf = ctx.createBuffer(1, data.length, ctx.sampleRate);
  buf.copyToChannel(data, 0);
  return { buf, hz };
}

// ---------------------------------------------------------------- live voices
function osc(ctx, type, hz, t, detuneCents = 0) {
  const o = ctx.createOscillator();
  o.type = type;
  o.frequency.setValueAtTime(hz, t);
  o.detune.value = detuneCents;
  return o;
}

function vibrato(ctx, oscs, t, { rate = 5, depth = 6, delay = 0.25 }) {
  const lfo = ctx.createOscillator(), amount = ctx.createGain();
  lfo.frequency.value = rate;
  amount.gain.setValueAtTime(0, t);
  amount.gain.linearRampToValueAtTime(depth, t + delay + 0.2);
  lfo.connect(amount);
  oscs.forEach((o) => amount.connect(o.detune));
  return lfo;
}

function envelope(ctx, t, dur, vel, { attack, release, sustain = 1 }) {
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vel, t + attack);
  if (sustain !== 1) g.gain.setTargetAtTime(vel * sustain, t + attack, dur * 0.4 + 0.05);
  const end = t + Math.max(dur, attack);
  g.gain.setValueAtTime(vel * sustain, end);
  g.gain.setTargetAtTime(0, end, release / 3);
  return { g, end: end + release };
}

// name -> { waves: [[type, detune cents, level]], filter, attack, release, vib, … }
const LIVE = {
  pad: { waves: [["sawtooth", -8, 0.5], ["sawtooth", 8, 0.5]], cutoff: 1100, q: 0.4, attack: 0.9, release: 1.6, gain: 0.35 },
  strings: { waves: [["sawtooth", -10, 0.4], ["sawtooth", 0, 0.4], ["sawtooth", 11, 0.4]], cutoff: 2300, q: 0.5, attack: 0.35, release: 0.9, vib: { rate: 5.2, depth: 9, delay: 0.3 }, gain: 0.28 },
  choir: { waves: [["sawtooth", -6, 0.5], ["sawtooth", 7, 0.5]], formants: [[700, 7, 1], [1150, 9, 0.6], [2600, 12, 0.25]], attack: 0.7, release: 1.3, vib: { rate: 4.6, depth: 7, delay: 0.4 }, gain: 1.1 },
  flute: { waves: [["sine", 0, 1], ["triangle", 0, 0.28]], cutoff: 3200, q: 0.3, attack: 0.07, release: 0.18, vib: { rate: 5, depth: 11, delay: 0.25 }, breath: 0.05, gain: 0.55 },
  reed: { waves: [["sawtooth", -5, 0.4], ["square", 6, 0.3]], cutoff: 1700, q: 1.2, attack: 0.04, release: 0.12, vib: { rate: 6.2, depth: 8, delay: 0.1 }, gain: 0.3 },
  brass: { waves: [["sawtooth", -6, 0.5], ["sawtooth", 6, 0.5]], cutoff: 1500, q: 1, filterEnv: 2.2, attack: 0.05, release: 0.2, vib: { rate: 5, depth: 6, delay: 0.3 }, gain: 0.34 },
  lead: { waves: [["square", 0, 0.5], ["square", 7, 0.25]], cutoff: 3000, q: 0.7, attack: 0.01, release: 0.09, vib: { rate: 6, depth: 10, delay: 0.18 }, gain: 0.22 },
  bass: { waves: [["triangle", 0, 1], ["sine", -1200, 0.6]], cutoff: 900, q: 0.5, attack: 0.012, release: 0.1, sustain: 0.75, gain: 0.8 },
  synthbass: { waves: [["sawtooth", 0, 0.6], ["square", -1200, 0.35]], cutoff: 700, q: 3, filterEnv: 2.5, attack: 0.006, release: 0.07, sustain: 0.6, gain: 0.42 },
};

function playLive(ctx, out, def, midi, t, dur, vel) {
  const hz = midiToHz(midi);
  const { g, end } = envelope(ctx, t, dur, vel * def.gain, def);
  const oscs = def.waves.map(([type, det, level]) => {
    const o = osc(ctx, type, hz, t, det);
    const lvl = ctx.createGain();
    lvl.gain.value = level;
    o.connect(lvl);
    return { o, lvl };
  });
  const mix = ctx.createGain();
  oscs.forEach(({ lvl }) => lvl.connect(mix));
  let tail = mix;
  if (def.formants) {
    // Vowel "ah": parallel resonances make saws sing.
    tail = ctx.createGain();
    for (const [f, q, a] of def.formants) {
      const bp = ctx.createBiquadFilter();
      bp.type = "bandpass"; bp.frequency.value = f; bp.Q.value = q;
      const lv = ctx.createGain(); lv.gain.value = a;
      mix.connect(bp).connect(lv).connect(tail);
    }
  } else {
    const lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.Q.value = def.q;
    const cut = Math.min(def.cutoff, 18000);
    if (def.filterEnv) {
      lp.frequency.setValueAtTime(cut * 0.25, t);
      lp.frequency.linearRampToValueAtTime(Math.min(cut * def.filterEnv, 18000), t + 0.03 + def.attack);
      lp.frequency.setTargetAtTime(cut, t + 0.05 + def.attack, 0.12);
    } else lp.frequency.value = cut;
    tail = mix.connect(lp);
  }
  tail.connect(g).connect(out);
  const stopAt = end + 0.05;
  const lfo = def.vib && vibrato(ctx, oscs.map((x) => x.o), t, def.vib);
  if (lfo) { lfo.start(t); lfo.stop(stopAt); }
  oscs.forEach(({ o }) => { o.start(t); o.stop(stopAt); });
  if (def.breath) breath(ctx, g, hz, t, end, def.breath);
}

let noiseBuf = null;
export function noiseBuffer(ctx) {
  if (!noiseBuf || noiseBuf.sampleRate !== ctx.sampleRate) {
    noiseBuf = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  return noiseBuf;
}

// The airy hiss of a flute.
function breath(ctx, out, hz, t, end, level) {
  const src = ctx.createBufferSource();
  src.buffer = noiseBuffer(ctx);
  src.loop = true;
  const bp = ctx.createBiquadFilter();
  bp.type = "bandpass"; bp.frequency.value = Math.min(hz * 2, 8000); bp.Q.value = 2;
  const g = ctx.createGain(); g.gain.value = level;
  src.connect(bp).connect(g).connect(out);
  src.start(t, Math.random());
  src.stop(end);
}

// ---------------------------------------------------------------- public
export const isDrum = (name) => name in DRUMS;
export const INSTRUMENTS = [...Object.keys(SAMPLED), ...Object.keys(LIVE), ...Object.keys(DRUMS)];

/** Pre-renders the buffers an instrument list needs (avoids a hiccup on the first note). */
export function warm(ctx, names) {
  for (const n of names) {
    if (SAMPLED[n]) ROOTS.forEach((r) => sampleFor(ctx, n, r));
    if (DRUMS[n]) drumFor(ctx, n);
  }
}

/**
 * Plays one note. `midi` is ignored for drums; `dur` (s) is how long a held note lasts.
 * `vel` 0..1, `pan` -1..1.
 */
export function playNote(ctx, out, name, midi, t, dur, vel = 0.7, pan = 0) {
  let dest = out;
  if (pan && ctx.createStereoPanner) {
    const p = ctx.createStereoPanner();
    p.pan.value = pan;
    p.connect(out);
    dest = p;
  }
  if (LIVE[name]) return playLive(ctx, dest, LIVE[name], midi, t, dur, vel);
  const def = SAMPLED[name] || DRUMS[name];
  if (!def) return;
  const { buf, hz } = SAMPLED[name] ? sampleFor(ctx, name, midi) : drumFor(ctx, name);
  const src = ctx.createBufferSource();
  src.buffer = buf;
  if (hz) src.playbackRate.value = midiToHz(midi) / hz;
  const g = ctx.createGain();
  g.gain.value = vel * def.gain;
  src.connect(g).connect(dest);
  src.start(t);
  // Damp a plucked note when the next one comes (keeps fast lines clean).
  if (SAMPLED[name] && dur < def.seconds) {
    g.gain.setValueAtTime(vel * def.gain, t + dur);
    g.gain.setTargetAtTime(0, t + dur, 0.12);
    src.stop(t + dur + 0.6);
  }
}
