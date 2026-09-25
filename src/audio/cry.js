import { DINOS } from "../data/dinos.js";
import { makeReverb, cryRoar, cryScreech, cryTrumpet, cryHiss, cryChirps, cryBellow, cryGrunt, cryWhaleCall, cryGrowl } from "./synth.js";

export function playCry(build) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  const ctx = new AC();
  // Resume if suspended (iOS Safari)
  if (ctx.state === "suspended") ctx.resume();

  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const tailD = DINOS[build.tail];
  const backLegsD = DINOS[build.backLegs];
  const backDorsalD = DINOS[build.back];

  const cryType = headD.cry;
  const params = {
    headSize: headD.head.size,
    bite: headD.head.bite,
    sharp: teethD.teeth.sharp,
    teethN: teethD.teeth.count,
    tailPow: tailD.tail.power,
    speed: backLegsD.backLegs.speed,
    armor: backDorsalD.back.armor,
    cryType,
  };

  // Master routing: dry + wet (reverb) buses
  const master = ctx.createGain();
  master.gain.value = 0.55;
  master.connect(ctx.destination);

  const isUnderwater = cryType.includes("underwater") || cryType.includes("whale");
  const isCold = cryType.includes("cold");
  const reverb = makeReverb(ctx,
    isUnderwater ? 3.5 : isCold ? 2.5 : 1.4,
    isUnderwater ? 2.5 : 2);
  reverb.connect(master);

  const sendDry = (node) => node.connect(master);
  const sendWet = (node, amount) => {
    const g = ctx.createGain();
    g.gain.value = amount;
    node.connect(g);
    g.connect(reverb);
  };

  const t0 = ctx.currentTime + 0.02;
  let duration;

  if (cryType.includes("chirp") || cryType.includes("trill")) {
    duration = cryChirps(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("screech")) {
    duration = cryScreech(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("trumpet") || cryType.includes("horn")) {
    duration = cryTrumpet(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("hiss")) {
    duration = cryHiss(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("bellow")) {
    duration = cryBellow(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("grunt") || cryType.includes("thud")) {
    duration = cryGrunt(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("whale") || cryType.includes("underwater")) {
    duration = cryWhaleCall(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("growl")) {
    duration = cryGrowl(ctx, t0, sendWet, sendDry, params);
  } else {
    duration = cryRoar(ctx, t0, sendWet, sendDry, params);
  }

  setTimeout(() => { try { ctx.close(); } catch (e) {} }, (duration + 3) * 1000);
}
