// Shared pieces of the music and ambience mixers: a per-device volume setting and
// a synthesized reverb.

/** A 0..1 volume remembered in localStorage (shared by every save slot). */
export function storedVolume(key, fallback) {
  let value = fallback;
  try {
    const v = parseFloat(localStorage.getItem(key));
    if (Number.isFinite(v)) value = Math.min(1, Math.max(0, v));
  } catch { /* storage unavailable */ }
  return {
    get: () => value,
    set(v) {
      value = Math.min(1, Math.max(0, v));
      try { localStorage.setItem(key, String(value)); } catch { /* storage unavailable */ }
      return value;
    },
  };
}

/** A stereo reverb: decaying noise, darker when `damp` is high (0..1). */
export function makeReverb(ctx, seconds, damp = 0.5) {
  const len = Math.floor(ctx.sampleRate * seconds);
  const ir = ctx.createBuffer(2, len, ctx.sampleRate);
  for (let ch = 0; ch < 2; ch++) {
    const d = ir.getChannelData(ch);
    let lp = 0;
    for (let i = 0; i < len; i++) {
      lp += (1 - damp * 0.9) * (Math.random() * 2 - 1 - lp);
      d[i] = lp * Math.pow(1 - i / len, 2.5);
    }
  }
  const conv = ctx.createConvolver();
  conv.buffer = ir;
  return conv;
}
