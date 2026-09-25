// ============ SOUND EFFECTS ============
export function playSfx(type) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    const ctx = new AC();
    if (ctx.state === "suspended") ctx.resume();
    const now = ctx.currentTime;

    if (type === "hit") {
      // Short thwack: noise burst + low thud
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.exponentialRampToValueAtTime(60, now + 0.08);
      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      osc.connect(gain).connect(ctx.destination);
      osc.start(now); osc.stop(now + 0.12);
    } else if (type === "crit") {
      // Louder crunch: distorted hit + high ring
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gain = ctx.createGain();
      osc1.type = "square"; osc1.frequency.value = 150;
      osc2.type = "sawtooth"; osc2.frequency.value = 800;
      osc2.frequency.exponentialRampToValueAtTime(200, now + 0.15);
      gain.gain.setValueAtTime(0.35, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc1.connect(gain); osc2.connect(gain); gain.connect(ctx.destination);
      osc1.start(now); osc1.stop(now + 0.1);
      osc2.start(now); osc2.stop(now + 0.2);
    } else if (type === "dodge") {
      // Whoosh: filtered noise sweep
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(400, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.15);
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc.connect(gain).connect(ctx.destination);
      osc.start(now); osc.stop(now + 0.2);
    } else if (type === "victory") {
      // Ascending arpeggio
      [523, 659, 784, 1047].forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "triangle";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0, now + i * 0.12);
        gain.gain.linearRampToValueAtTime(0.2, now + i * 0.12 + 0.05);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.12 + 0.3);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now + i * 0.12); osc.stop(now + i * 0.12 + 0.3);
      });
    } else if (type === "lastbreath") {
      // Dramatic low chord
      [110, 138, 165].forEach((freq) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sawtooth";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now); osc.stop(now + 0.6);
      });
    } else if (type === "defeat") {
      // Descending sad notes
      [400, 350, 280].forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.15, now + i * 0.2);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.2 + 0.25);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now + i * 0.2); osc.stop(now + i * 0.2 + 0.25);
      });
    }
    setTimeout(() => ctx.close(), 1500);
  } catch(e) {}
}

// ============ HAPTIC FEEDBACK ============
// ============ DINO ROAR ============
export function playRoar(family) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    const ctx = new AC();
    const now = ctx.currentTime;
    const master = ctx.createGain();
    master.gain.value = 0.3;
    master.connect(ctx.destination);

    if (family === "tyrant" || family === "armored") {
      // Deep rumbling roar
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(90, now);
      osc.frequency.exponentialRampToValueAtTime(55, now + 0.8);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.4, now);
      g.gain.linearRampToValueAtTime(0.6, now + 0.15);
      g.gain.exponentialRampToValueAtTime(0.01, now + 1.2);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 200;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 1.3);
      // Sub-rumble
      const sub = ctx.createOscillator();
      sub.type = "sine"; sub.frequency.value = 35;
      const sg = ctx.createGain();
      sg.gain.setValueAtTime(0.3, now);
      sg.gain.exponentialRampToValueAtTime(0.01, now + 1.5);
      sub.connect(sg).connect(master);
      sub.start(now); sub.stop(now + 1.5);
    } else if (family === "raptor" || family === "spino") {
      // High-pitched screech
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.1);
      osc.frequency.exponentialRampToValueAtTime(600, now + 0.5);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0, now);
      g.gain.linearRampToValueAtTime(0.35, now + 0.05);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.7);
      const filt = ctx.createBiquadFilter();
      filt.type = "bandpass"; filt.frequency.value = 900; filt.Q.value = 3;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.8);
    } else if (family === "sauropod" || family === "hadrosaur") {
      // Long low-frequency call (like a foghorn)
      const osc = ctx.createOscillator();
      osc.type = "triangle";
      osc.frequency.setValueAtTime(100, now);
      osc.frequency.linearRampToValueAtTime(130, now + 0.5);
      osc.frequency.linearRampToValueAtTime(80, now + 1.5);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0, now);
      g.gain.linearRampToValueAtTime(0.4, now + 0.3);
      g.gain.setValueAtTime(0.4, now + 1.0);
      g.gain.exponentialRampToValueAtTime(0.01, now + 2.0);
      osc.connect(g).connect(master);
      osc.start(now); osc.stop(now + 2.1);
    } else if (family === "flyer") {
      // Pteranodon shriek
      const osc = ctx.createOscillator();
      osc.type = "square";
      osc.frequency.setValueAtTime(1500, now);
      osc.frequency.exponentialRampToValueAtTime(2000, now + 0.08);
      osc.frequency.exponentialRampToValueAtTime(800, now + 0.4);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.15, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.5);
      const filt = ctx.createBiquadFilter();
      filt.type = "highpass"; filt.frequency.value = 600;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.6);
    } else if (family === "marine") {
      // Underwater bellow
      const osc = ctx.createOscillator();
      osc.type = "sine";
      osc.frequency.setValueAtTime(60, now);
      osc.frequency.linearRampToValueAtTime(90, now + 0.5);
      osc.frequency.linearRampToValueAtTime(45, now + 1.8);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.3, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 2.0);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 150;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 2.1);
    } else {
      // Generic growl
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(150, now);
      osc.frequency.exponentialRampToValueAtTime(80, now + 0.6);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.3, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.8);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 300;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.9);
    }
    setTimeout(() => ctx.close(), 3000);
  } catch(e) {}
}

export function vibrate(pattern) {
  try { if (navigator.vibrate) navigator.vibrate(pattern); } catch(e) {}
}
