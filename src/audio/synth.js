// ============ AUDIO ENGINE v2 — distinctive cries per family ============

export function makeNoise(ctx, duration) {
  const buf = ctx.createBuffer(1, ctx.sampleRate * duration, ctx.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  return src;
}

export function makeReverb(ctx, duration, decay) {
  const rate = ctx.sampleRate;
  const length = rate * duration;
  const impulse = ctx.createBuffer(2, length, rate);
  for (let ch = 0; ch < 2; ch++) {
    const d = impulse.getChannelData(ch);
    for (let i = 0; i < length; i++) {
      d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay);
    }
  }
  const conv = ctx.createConvolver();
  conv.buffer = impulse;
  return conv;
}

export function makeDistortion(ctx, amount) {
  const ws = ctx.createWaveShaper();
  const n = 2048;
  const curve = new Float32Array(n);
  const k = amount;
  for (let i = 0; i < n; i++) {
    const x = (i * 2) / n - 1;
    curve[i] = ((3 + k) * x * 20 * Math.PI / 180) / (Math.PI + k * Math.abs(x));
  }
  ws.curve = curve;
  ws.oversample = "4x";
  return ws;
}

// ---------- Individual cry generators ----------

export function cryRoar(ctx, t0, sendWet, sendDry, p) {
  // Deep, gritty, formant-shaped roar. Scales with head/bite/sharp/tailPow.
  const { headSize, bite, sharp, tailPow, cryType } = p;
  const baseFreq = 55 + (10 - headSize) * 9; // 55-145 Hz
  const duration = 1.2 + headSize * 0.15 + tailPow * 0.04;
  const isDeep = cryType.includes("deep");
  const isCold = cryType.includes("cold");
  const isMuffled = cryType.includes("muffled");
  const finalFreq = isDeep ? baseFreq * 0.55 : baseFreq * 0.75;

  // Main body: detuned sawtooths for thickness
  const osc1 = ctx.createOscillator(); osc1.type = "sawtooth";
  const osc2 = ctx.createOscillator(); osc2.type = "sawtooth";
  osc1.frequency.setValueAtTime(baseFreq * 1.4, t0);
  osc1.frequency.exponentialRampToValueAtTime(finalFreq, t0 + duration * 0.9);
  osc2.frequency.setValueAtTime(baseFreq * 1.4 * 1.01, t0); // slight detune
  osc2.frequency.exponentialRampToValueAtTime(finalFreq * 1.01, t0 + duration * 0.9);

  // Sub-bass rumble
  const sub = ctx.createOscillator(); sub.type = "sine";
  sub.frequency.setValueAtTime(baseFreq * 0.5, t0);
  sub.frequency.linearRampToValueAtTime(baseFreq * 0.35, t0 + duration);

  // Formant filters (throat/mouth resonance)
  const formant1 = ctx.createBiquadFilter();
  formant1.type = "bandpass"; formant1.Q.value = 6;
  formant1.frequency.value = 350 + bite * 25;
  const formant2 = ctx.createBiquadFilter();
  formant2.type = "bandpass"; formant2.Q.value = 4;
  formant2.frequency.value = 1100;

  // Distortion for aggression
  const dist = makeDistortion(ctx, 10 + sharp * 2);

  // Growl tremolo (amplitude wobble)
  const lfo = ctx.createOscillator();
  lfo.frequency.value = 6 + sharp * 0.4;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = 0.25;
  const tremolo = ctx.createGain();
  tremolo.gain.value = 0.75;
  lfo.connect(lfoGain);
  lfoGain.connect(tremolo.gain);

  // Breath noise layer
  const noise = makeNoise(ctx, duration);
  const breathFilter = ctx.createBiquadFilter();
  breathFilter.type = "highpass"; breathFilter.frequency.value = 1800;
  const breathGain = ctx.createGain();
  breathGain.gain.setValueAtTime(0, t0);
  breathGain.gain.linearRampToValueAtTime(0.05, t0 + 0.08);
  breathGain.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  // Muffled (underwater) lowpass
  const muffle = ctx.createBiquadFilter();
  muffle.type = "lowpass";
  muffle.frequency.value = isMuffled ? 700 : isCold ? 3000 : 8000;
  muffle.Q.value = 1;

  // Master envelope
  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.4, t0 + 0.1);
  env.gain.setValueAtTime(0.4, t0 + duration * 0.65);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  // Wiring
  osc1.connect(dist); osc2.connect(dist);
  dist.connect(formant1); formant1.connect(formant2); formant2.connect(tremolo);
  sub.connect(tremolo);
  tremolo.connect(muffle);
  noise.connect(breathFilter); breathFilter.connect(muffle);
  muffle.connect(env);
  sendDry(env); sendWet(env, isMuffled ? 0.6 : 0.2);

  osc1.start(t0); osc1.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  sub.start(t0); sub.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  noise.start(t0); noise.stop(t0 + duration);
  return duration;
}

export function cryScreech(ctx, t0, sendWet, sendDry, p) {
  const { sharp, headSize, speed, cryType } = p;
  const isHigh = cryType.includes("high");
  const isDeep = cryType.includes("deep");
  const baseFreq = isDeep ? 400 : isHigh ? 1200 : 700 + sharp * 40;
  const duration = 0.5 + speed * 0.04;

  // Main squeal
  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq * 0.5, t0);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.4, t0 + duration * 0.3);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.8, t0 + duration);

  // Harmonic shimmer
  const osc2 = ctx.createOscillator();
  osc2.type = "square";
  osc2.frequency.setValueAtTime(baseFreq * 1.51, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 2.4, t0 + duration * 0.4);

  // Opening noise burst (air)
  const noise = makeNoise(ctx, 0.15);
  const noiseFilter = ctx.createBiquadFilter();
  noiseFilter.type = "bandpass";
  noiseFilter.frequency.value = 3000;
  noiseFilter.Q.value = 2;
  const noiseEnv = ctx.createGain();
  noiseEnv.gain.setValueAtTime(0.3, t0);
  noiseEnv.gain.exponentialRampToValueAtTime(0.001, t0 + 0.12);

  // Harsh distortion
  const dist = makeDistortion(ctx, 20 + sharp);

  // Bandpass for piercing quality
  const bp = ctx.createBiquadFilter();
  bp.type = "bandpass";
  bp.frequency.value = baseFreq * 1.2;
  bp.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.02);
  env.gain.setValueAtTime(0.35, t0 + duration * 0.5);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(dist); osc2.connect(dist);
  dist.connect(bp);
  bp.connect(env);
  noise.connect(noiseFilter); noiseFilter.connect(noiseEnv); noiseEnv.connect(env);

  sendDry(env); sendWet(env, 0.2);

  osc.start(t0); osc.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  noise.start(t0); noise.stop(t0 + 0.15);
  return duration;
}

export function cryTrumpet(ctx, t0, sendWet, sendDry, p) {
  // Brass-like resonant tone (Parasaurolophus famous cry). Clean harmonics.
  const { headSize, tailPow, cryType } = p;
  const isLow = cryType.includes("low") || cryType.includes("horn");
  const isSoft = cryType.includes("soft");
  const baseFreq = isLow ? 70 + (10 - headSize) * 8 : 150 + (10 - headSize) * 12;
  const duration = isLow ? 2.2 + headSize * 0.15 : 1.4 + tailPow * 0.06;

  // Harmonic series (like a trombone)
  const harmonics = [1, 2, 3, 4, 5, 6];
  const gains = [1.0, 0.5, 0.4, 0.25, 0.15, 0.08];
  const oscs = harmonics.map((h, i) => {
    const o = ctx.createOscillator();
    o.type = i === 0 ? "sine" : "triangle";
    o.frequency.setValueAtTime(baseFreq * h * 0.9, t0);
    o.frequency.exponentialRampToValueAtTime(baseFreq * h, t0 + 0.15);
    o.frequency.setValueAtTime(baseFreq * h, t0 + duration * 0.7);
    o.frequency.exponentialRampToValueAtTime(baseFreq * h * 0.95, t0 + duration);
    return { osc: o, gain: gains[i], h };
  });

  // Slight vibrato
  const vib = ctx.createOscillator();
  vib.frequency.value = 5;
  const vibGain = ctx.createGain();
  vibGain.gain.value = baseFreq * 0.015;
  vib.connect(vibGain);
  oscs.forEach(({ osc }) => vibGain.connect(osc.frequency));

  // Resonant bandpass (horn body)
  const resonance = ctx.createBiquadFilter();
  resonance.type = "bandpass";
  resonance.frequency.value = baseFreq * 2.5;
  resonance.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(isSoft ? 0.25 : 0.4, t0 + 0.25); // slow attack like brass
  env.gain.setValueAtTime(isSoft ? 0.25 : 0.4, t0 + duration * 0.75);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  const mix = ctx.createGain();
  oscs.forEach(({ osc, gain }) => {
    const g = ctx.createGain();
    g.gain.value = gain;
    osc.connect(g);
    g.connect(mix);
  });
  mix.connect(resonance);
  resonance.connect(env);
  sendDry(env); sendWet(env, 0.35);

  oscs.forEach(({ osc }) => { osc.start(t0); osc.stop(t0 + duration); });
  vib.start(t0); vib.stop(t0 + duration);
  return duration;
}

export function cryHiss(ctx, t0, sendWet, sendDry, p) {
  const { sharp, headSize, cryType } = p;
  const hasRoar = cryType.includes("roar");
  const duration = 1.0 + headSize * 0.08;

  // Main hiss: filtered noise
  const noise = makeNoise(ctx, duration);
  const bp = ctx.createBiquadFilter();
  bp.type = "bandpass";
  bp.frequency.setValueAtTime(2500 + sharp * 200, t0);
  bp.frequency.linearRampToValueAtTime(1800, t0 + duration);
  bp.Q.value = 4;

  // Slight pitched growl under if it's a hiss-roar
  let roarOsc = null, roarEnv = null;
  if (hasRoar) {
    roarOsc = ctx.createOscillator();
    roarOsc.type = "sawtooth";
    roarOsc.frequency.value = 80 + (10 - headSize) * 8;
    roarEnv = ctx.createGain();
    roarEnv.gain.setValueAtTime(0, t0);
    roarEnv.gain.linearRampToValueAtTime(0.2, t0 + 0.2);
    roarEnv.gain.exponentialRampToValueAtTime(0.001, t0 + duration);
    const roarFilter = ctx.createBiquadFilter();
    roarFilter.type = "lowpass";
    roarFilter.frequency.value = 600;
    roarOsc.connect(roarFilter);
    roarFilter.connect(roarEnv);
  }

  // Amplitude tremolo for snake-like quality
  const lfo = ctx.createOscillator();
  lfo.frequency.value = 4;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = 0.08;
  const trem = ctx.createGain();
  trem.gain.value = 0.22;
  lfo.connect(lfoGain);
  lfoGain.connect(trem.gain);

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.22, t0 + 0.05);
  env.gain.setValueAtTime(0.22, t0 + duration * 0.8);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  noise.connect(bp); bp.connect(trem); trem.connect(env);
  if (roarEnv) roarEnv.connect(env);
  sendDry(env); sendWet(env, 0.2);

  noise.start(t0); noise.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  if (roarOsc) { roarOsc.start(t0); roarOsc.stop(t0 + duration); }
  return duration;
}

export function cryChirps(ctx, t0, sendWet, sendDry, p) {
  const { sharp, speed, headSize, cryType } = p;
  const isMelodic = cryType.includes("melodic");
  const isTrill = cryType.includes("trill");
  const isLoud = cryType.includes("loud");
  const chirpCount = isTrill ? 6 : 3 + Math.floor(speed / 3);
  const chirpDur = 0.08 + sharp * 0.01;
  const gap = isMelodic ? 0.14 : 0.1;
  const baseFreq = 800 + (10 - headSize) * 60;
  const notes = isMelodic ? [1, 1.2, 1.5, 1.2, 1, 0.8] : [1, 1.15, 0.95, 1.1];

  for (let i = 0; i < chirpCount; i++) {
    const start = t0 + i * gap;
    const noteFreq = baseFreq * notes[i % notes.length];

    const osc = ctx.createOscillator();
    osc.type = "triangle";
    osc.frequency.setValueAtTime(noteFreq * 0.7, start);
    osc.frequency.exponentialRampToValueAtTime(noteFreq * 1.2, start + chirpDur * 0.5);
    osc.frequency.exponentialRampToValueAtTime(noteFreq, start + chirpDur);

    const osc2 = ctx.createOscillator();
    osc2.type = "sine";
    osc2.frequency.setValueAtTime(noteFreq * 2, start);
    osc2.frequency.exponentialRampToValueAtTime(noteFreq * 2.4, start + chirpDur);
    const g2 = ctx.createGain();
    g2.gain.value = 0.3;

    const env = ctx.createGain();
    env.gain.setValueAtTime(0, start);
    env.gain.linearRampToValueAtTime(isLoud ? 0.35 : 0.22, start + 0.01);
    env.gain.exponentialRampToValueAtTime(0.001, start + chirpDur);

    osc.connect(env);
    osc2.connect(g2); g2.connect(env);
    sendDry(env); sendWet(env, 0.3);
    osc.start(start); osc.stop(start + chirpDur);
    osc2.start(start); osc2.stop(start + chirpDur);
  }
  return chirpCount * gap + chirpDur;
}

export function cryBellow(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, cryType } = p;
  const isDeep = cryType.includes("deep");
  const isSoft = cryType.includes("soft");
  const baseFreq = isDeep ? 80 + (10 - headSize) * 7 : 130 + (10 - headSize) * 10;
  const duration = 1.3 + tailPow * 0.08;

  const osc1 = ctx.createOscillator();
  osc1.type = "sawtooth";
  osc1.frequency.setValueAtTime(baseFreq * 0.85, t0);
  osc1.frequency.exponentialRampToValueAtTime(baseFreq, t0 + 0.2);
  osc1.frequency.setValueAtTime(baseFreq, t0 + duration * 0.7);
  osc1.frequency.exponentialRampToValueAtTime(baseFreq * 0.7, t0 + duration);

  const osc2 = ctx.createOscillator();
  osc2.type = "triangle";
  osc2.frequency.setValueAtTime(baseFreq * 1.5, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 1.2, t0 + duration);

  const formant = ctx.createBiquadFilter();
  formant.type = "bandpass";
  formant.frequency.value = 500;
  formant.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(isSoft ? 0.28 : 0.42, t0 + 0.15);
  env.gain.setValueAtTime(isSoft ? 0.28 : 0.42, t0 + duration * 0.7);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc1.connect(formant); osc2.connect(formant);
  formant.connect(env);
  sendDry(env); sendWet(env, 0.25);
  osc1.start(t0); osc1.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  return duration;
}

export function cryGrunt(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, armor, cryType } = p;
  const isDeep = cryType.includes("deep");
  const isThud = cryType.includes("thud");
  const baseFreq = isDeep ? 60 + (10 - headSize) * 5 : 100 + (10 - headSize) * 6;
  const duration = 0.5 + tailPow * 0.04;

  // Percussive thud at start if thud-cry
  if (isThud) {
    const thud = ctx.createOscillator();
    thud.type = "sine";
    thud.frequency.setValueAtTime(80, t0);
    thud.frequency.exponentialRampToValueAtTime(30, t0 + 0.1);
    const thudEnv = ctx.createGain();
    thudEnv.gain.setValueAtTime(0.6, t0);
    thudEnv.gain.exponentialRampToValueAtTime(0.001, t0 + 0.12);
    thud.connect(thudEnv);
    sendDry(thudEnv); sendWet(thudEnv, 0.3);
    thud.start(t0); thud.stop(t0 + 0.12);
  }

  const startOffset = isThud ? 0.08 : 0;
  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq * 1.2, t0 + startOffset);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.7, t0 + startOffset + duration);

  const dist = makeDistortion(ctx, 15);
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = 1200;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0 + startOffset);
  env.gain.linearRampToValueAtTime(0.38, t0 + startOffset + 0.03);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + startOffset + duration);

  osc.connect(dist); dist.connect(lp); lp.connect(env);
  sendDry(env); sendWet(env, 0.15);
  osc.start(t0 + startOffset); osc.stop(t0 + startOffset + duration);
  return duration + startOffset;
}

export function cryWhaleCall(ctx, t0, sendWet, sendDry, p) {
  const { headSize, cryType } = p;
  const isUnderwater = cryType.includes("underwater");
  const duration = isUnderwater ? 1.8 + headSize * 0.1 : 2.5 + headSize * 0.12;

  const osc = ctx.createOscillator();
  osc.type = "sine";
  const baseFreq = 180 + (10 - headSize) * 12;

  // Cetacean-style glissando
  osc.frequency.setValueAtTime(baseFreq * 0.7, t0);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.3, t0 + duration * 0.3);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.9, t0 + duration * 0.6);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.5, t0 + duration);

  // Harmonic
  const osc2 = ctx.createOscillator();
  osc2.type = "triangle";
  osc2.frequency.setValueAtTime(baseFreq * 1.5, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 2, t0 + duration * 0.3);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq, t0 + duration);
  const g2 = ctx.createGain(); g2.gain.value = 0.2;

  // Vibrato
  const vib = ctx.createOscillator();
  vib.frequency.value = 4.5;
  const vibGain = ctx.createGain();
  vibGain.gain.value = baseFreq * 0.04;
  vib.connect(vibGain);
  vibGain.connect(osc.frequency);

  // Lowpass if underwater (muffled)
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = isUnderwater ? 900 : 3500;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.3);
  env.gain.setValueAtTime(0.35, t0 + duration * 0.75);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(lp); osc2.connect(g2); g2.connect(lp);
  lp.connect(env);
  sendDry(env); sendWet(env, isUnderwater ? 0.7 : 0.5);

  osc.start(t0); osc.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  vib.start(t0); vib.stop(t0 + duration);
  return duration;
}

export function cryGrowl(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, cryType } = p;
  const isWet = cryType.includes("wet");
  const baseFreq = 70 + (10 - headSize) * 7;
  const duration = 0.9 + tailPow * 0.04;

  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq, t0);
  osc.frequency.linearRampToValueAtTime(baseFreq * 0.7, t0 + duration);

  const dist = makeDistortion(ctx, 18);
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = isWet ? 800 : 1500;

  // Gurgle wobble
  const lfo = ctx.createOscillator();
  lfo.frequency.value = isWet ? 12 : 7;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = baseFreq * 0.15;
  lfo.connect(lfoGain);
  lfoGain.connect(osc.frequency);

  // Wet bubbles layer
  if (isWet) {
    const noise = makeNoise(ctx, duration);
    const noiseBP = ctx.createBiquadFilter();
    noiseBP.type = "bandpass"; noiseBP.frequency.value = 500; noiseBP.Q.value = 8;
    const noiseEnv = ctx.createGain();
    noiseEnv.gain.setValueAtTime(0.12, t0);
    noiseEnv.gain.exponentialRampToValueAtTime(0.001, t0 + duration);
    noise.connect(noiseBP); noiseBP.connect(noiseEnv);
    const wetOut = noiseEnv;
    sendDry(wetOut); sendWet(wetOut, 0.3);
    noise.start(t0); noise.stop(t0 + duration);
  }

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.08);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(dist); dist.connect(lp); lp.connect(env);
  sendDry(env); sendWet(env, 0.25);

  osc.start(t0); osc.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  return duration;
}
