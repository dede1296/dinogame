// Front and back views of a hybrid, built from the same donor parts as the side view
// (dinoArt.js). Used when a dino walks toward or away from the camera.
//
// Coordinates: x centered on the dino, ground at y = 0, up is negative.

import { DINOS } from "../../../src/data/dinos.js";
import { makePalette } from "./palette.js";
import { tube } from "./geometry.js";
import { PREDATORS, BIPED, QUAD, isFierce, PEBBLE_TILE, pebbleTile } from "./dinoArt.js";

const OUT = 3.2;

const BODY = {
  biped: { w: 86, h: 94, cy: -112 },
  quad: { w: 130, h: 86, cy: -82 },
  flyer: { w: 62, h: 58, cy: -56 },
  marine: { w: 134, h: 58, cy: -42 },
};

// Head size in the front view per family, and extra features.
const HEADS = {
  tyrant: { w: 74, h: 58, neck: 16 },
  raptor: { w: 46, h: 42, neck: 26 },
  sauropod: { w: 34, h: 30, neck: 150 },
  ceratopsian: { w: 60, h: 54, neck: 4 },
  armored: { w: 66, h: 40, neck: 2 },
  hadrosaur: { w: 48, h: 48, neck: 30 },
  spino: { w: 42, h: 54, neck: 28 },
  flyer: { w: 36, h: 34, neck: 30 },
  marine: { w: 64, h: 44, neck: 12 },
};

function postureOf(d) {
  if (BIPED.has(d.family)) return "biped";
  if (QUAD.has(d.family)) return "quad";
  return d.family === "flyer" ? "flyer" : "marine";
}

const e = (cx, cy, rx, ry, fill, p, sw = OUT) =>
  `<ellipse cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" rx="${rx.toFixed(1)}" ry="${ry.toFixed(1)}" fill="${fill}" stroke="${p.outline}" stroke-width="${sw}"/>`;
const path = (d, fill, p, sw = OUT) => `<path d="${d}" fill="${fill}" stroke="${p.outline}" stroke-width="${sw}" stroke-linejoin="round"/>`;

function claws3(x, y, p) {
  return [-6, 0, 6].map((dx) => `<path d="M ${x + dx - 2.5},${y} L ${x + dx},${y + 6} L ${x + dx + 2.5},${y} Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="1.6" stroke-linejoin="round"/>`).join("");
}

// ---------------------------------------------------------------- legs
function legs(posture, backLegsD, frontD, B, p, id, view) {
  const skin = `url(#${id}-body)`, far = `url(#${id}-far)`;
  const pw = backLegsD.backLegs.power, fp = frontD.frontLegs.power;
  let behind = "", front = "";
  if (posture === "biped") {
    for (const s of [-1, 1]) {
      const x = s * (B.w * 0.3);
      front += path(tube([[x, B.cy + B.h * 0.25], [x + s * 4, -34], [x, -8]], [30 + pw * 1.2, 22, 16]), skin, p);
      front += e(x, -5, 14, 6, skin, p);
      if (view === "front") front += claws3(x, -2, p);
    }
    if (view === "front") {
      // Arms held in front of the chest.
      const arm = frontD.family === "tyrant" ? 14 : 20 + frontD.frontLegs.reach * 1.5;
      for (const s of [-1, 1]) {
        const x = s * B.w * 0.22, y = B.cy + 4;
        front += path(tube([[x, y], [x + s * 4, y + arm * 0.6], [x + s * 2, y + arm]], [14 + fp * 0.5, 11, 9]), skin, p);
        front += claws3(x + s * 2, y + arm + 2, p);
      }
    }
  } else if (posture === "quad") {
    for (const s of [-1, 1]) {
      const bx = s * B.w * 0.36, fx = s * B.w * 0.3;
      behind += path(tube([[bx, B.cy + 10], [bx, -24], [bx, -12]], [30 + pw, 26, 24]), far, p);
      front += path(tube([[fx, B.cy + B.h * 0.2], [fx, -26], [fx, -8]], [30 + fp * 1.2, 26, 26]), skin, p);
      front += e(fx, -6, 15, 6, skin, p);
      front += [-7, 0, 7].map((dx) => `<ellipse cx="${fx + dx}" cy="-3" rx="3.5" ry="2.6" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="1.4"/>`).join("");
    }
  } else if (posture === "flyer") {
    for (const s of [-1, 1]) {
      const span = 130 + frontD.frontLegs.reach * 6;
      behind += path(`M ${s * 20},${B.cy - 14} C ${s * 60},${B.cy - 80} ${s * span * 0.7},${B.cy - 96} ${s * span},${B.cy - 70} C ${s * span * 0.8},${B.cy - 40} ${s * span * 0.6},${B.cy - 10} ${s * span * 0.45},${B.cy + 8} C ${s * 70},${B.cy} ${s * 40},${B.cy + 14} ${s * 22},${B.cy + 16} Z`, `url(#${id}-wing)`, p);
      behind += `<path d="M ${s * 20},${B.cy - 14} C ${s * 60},${B.cy - 80} ${s * span * 0.7},${B.cy - 96} ${s * span},${B.cy - 70}" fill="none" stroke="${p.outline}" stroke-width="5" stroke-linecap="round"/>`;
      front += path(tube([[s * 14, B.cy + 20], [s * 16, -14], [s * 14, -4]], [12, 9, 8]), skin, p) + claws3(s * 14, -2, p);
    }
  } else {
    for (const s of [-1, 1]) {
      behind += path(`M ${s * B.w * 0.3},${B.cy} C ${s * B.w * 0.7},${B.cy - 4} ${s * B.w * 0.85},${B.cy + 16} ${s * B.w * 0.8},${B.cy + 30} C ${s * B.w * 0.6},${B.cy + 28} ${s * B.w * 0.4},${B.cy + 18} ${s * B.w * 0.3},${B.cy + 14} Z`, skin, p);
    }
  }
  return { behind, front };
}

// ---------------------------------------------------------------- dorsal & tail
function dorsal(backD, B, p, id, view) {
  const { family } = backD;
  const { spikes, armor } = backD.back;
  const top = B.cy - B.h / 2;
  const acc = `url(#${id}-accent)`;
  if (family === "spino") {
    const h = 44 + spikes * 6;
    const fin = path(`M -9,${top + 18} Q -12,${top - h * 0.6} 0,${top - h} Q 12,${top - h * 0.6} 9,${top + 18} Z`, acc, p);
    const ribs = view === "back" ? `<path d="M 0,${top - h + 8} L 0,${top + 12}" stroke="${p.accentShade}" stroke-width="3"/>` : "";
    return { svg: fin + ribs, onTop: view === "back" };
  }
  if (family === "armored" && spikes >= 9) {
    const plates = [-1, 1, -1, 1].map((s, i) => {
      const x = s * 8, y = top + 6 + (view === "back" ? i * 16 : 0) - (view === "back" ? 0 : i * 2);
      const sz = 18 + (i === 1 || i === 2 ? 8 : 0);
      return path(`M ${x - 9},${y + 6} L ${x},${y - sz} L ${x + 9},${y + 6} Z`, acc, p);
    });
    return { svg: plates.join(""), onTop: view === "back" };
  }
  if (family === "armored" || (family === "ceratopsian" && armor >= 8)) {
    const bumps = [];
    const rows = view === "back" ? 3 : 1;
    for (let r = 0; r < rows; r++) for (const x of [-30, -12, 12, 30]) {
      const y = top + 10 + r * 18 - Math.abs(x) * 0.15;
      bumps.push(e(x, y, 8, 5, acc, p, 2.4));
      if (spikes >= 6) bumps.push(`<path d="M ${x - 4},${y - 3} L ${x},${y - 14} L ${x + 4},${y - 3} Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="1.8"/>`);
    }
    return { svg: bumps.join(""), onTop: true };
  }
  if (family === "raptor") {
    const tufts = [-18, -6, 6, 18].map((x) => path(`M ${x - 5},${top + 8} Q ${x - 6},${top - 12} ${x},${top - 18} Q ${x + 6},${top - 12} ${x + 5},${top + 8} Z`, p.accent, p, 2));
    return { svg: tufts.join(""), onTop: false };
  }
  if ((family === "tyrant" && spikes >= 4) || (family === "sauropod" && spikes >= 6)) {
    const cones = [-10, 0, 10].map((x, i) => path(`M ${x - 5},${top + 8} L ${x},${top - 8 - spikes - (i === 1 ? 6 : 0)} L ${x + 5},${top + 8} Z`, p.accent, p, 2.2));
    return { svg: cones.join(""), onTop: view === "back" };
  }
  if (family === "marine") return { svg: path(`M -7,${top + 12} Q 0,${top - 34} 7,${top + 12} Z`, acc, p), onTop: false };
  return { svg: "", onTop: false };
}

function tail(tailD, backD, B, p, id, view) {
  const L = 50 + tailD.tail.length * 6, th = 22 + tailD.tail.power * 1.4;
  const skin = `url(#${id}-body)`;
  if (view === "front") {
    // Only the tip shows, sweeping out from behind the body.
    const pts = [[B.w * 0.2, B.cy + B.h * 0.2], [B.w * 0.55, B.cy + B.h * 0.4], [B.w * 0.55 + L * 0.5, B.cy + B.h * 0.3]];
    return path(tube(pts, [th * 0.8, th * 0.45, 5]), skin, p);
  }
  // Back view: the tail runs toward the camera and down to the ground.
  const pts = [[0, B.cy + B.h * 0.05], [B.w * 0.14, B.cy + B.h * 0.45], [B.w * 0.36, -18], [B.w * 0.52 + L * 0.2, -2]];
  let orn = "";
  const tip = pts[pts.length - 1];
  if (tailD.family === "armored" && tailD.back.spikes >= 9) {
    orn = [-1, 1].map((s) => path(`M ${tip[0] - 4},${tip[1] - 12} L ${tip[0] + s * 26},${tip[1] - 22} L ${tip[0] + 4},${tip[1] - 4} Z`, p.clawFill, p, 2.2)).join("");
  } else if (tailD.family === "armored" && tailD.tail.power >= 9) {
    orn = e(tip[0], tip[1] - 6, 16, 11, `url(#${id}-accent)`, p);
  } else if (tailD.family === "marine") {
    orn = path(`M ${tip[0] - 22},${tip[1] - 2} Q ${tip[0]},${tip[1] - 14} ${tip[0] + 22},${tip[1] - 2} Q ${tip[0]},${tip[1] + 6} ${tip[0] - 22},${tip[1] - 2} Z`, `url(#${id}-accent)`, p);
  }
  return path(tube(pts, [th * 1.15, th * 0.85, th * 0.5, 7]), skin, p) + orn;
}

// ---------------------------------------------------------------- head
function head(headD, teethD, B, p, id, view, fierce) {
  const fam = headD.family;
  const H = HEADS[fam] || HEADS.tyrant;
  const s = 0.82 + headD.head.size * 0.04;
  const w = H.w * s, h = H.h * s;
  const top = B.cy - B.h / 2;
  const hy = top - H.neck - h * 0.35;
  const skin = `url(#${id}-body)`;
  let out = "";
  // Neck.
  if (H.neck > 6) out += path(tube([[0, top + 16], [0, (top + hy) / 2], [0, hy + h * 0.2]], [w * 0.7, w * 0.62, w * 0.55]), skin, p);

  // Features behind the skull.
  if (fam === "ceratopsian") {
    let rim = "";
    for (let i = 0; i < 11; i++) {
      const a = Math.PI + (i / 10) * Math.PI, r1 = w * 0.95, r2 = w * 1.12;
      rim += `${i ? "L" : "M"} ${(Math.cos(a) * (i % 2 ? r2 : r1)).toFixed(1)},${(hy - 6 + Math.sin(a) * (i % 2 ? r2 : r1)).toFixed(1)} `;
    }
    out += path(`${rim} L ${w * 0.95},${hy + 8} L ${-w * 0.95},${hy + 8} Z`, `url(#${id}-accent)`, p);
    out += `<path d="M ${-w * 0.65},${hy - 6} A ${w * 0.65} ${w * 0.65} 0 0 1 ${w * 0.65},${hy - 6}" fill="none" stroke="${p.accentShade}" stroke-width="2.5" opacity="0.7"/>`;
  }
  if (fam === "hadrosaur") out += path(tube([[0, hy - h * 0.3], [-4, hy - h * 0.9], [-10, hy - h * 1.35]], [16, 14, 11]), p.accent, p);
  if (fam === "flyer") out += path(`M -4,${hy - h * 0.2} L -8,${hy - h * 1.6} L 6,${hy - h * 0.3} Z`, p.accent, p);
  if (fam === "raptor") out += [-10, -3, 4, 11].map((x) => path(`M ${x - 3},${hy - h * 0.35} Q ${x - 6},${hy - h * 0.9} ${x + 2},${hy - h * 1.05} Q ${x + 2},${hy - h * 0.7} ${x + 3},${hy - h * 0.35} Z`, p.accent, p, 1.8)).join("");

  // Skull.
  out += e(0, hy, w / 2, h / 2, skin, p);
  if (fam === "armored") out += [-1, 0, 1].map((k) => e(k * w * 0.28, hy - h * 0.34, 7, 4.5, `url(#${id}-accent)`, p, 2)).join("");
  if (fam === "spino" || fam === "tyrant") out += path(`M -6,${hy - h * 0.48} Q 0,${hy - h * 0.72} 6,${hy - h * 0.48} Z`, p.shade, p, 2);

  if (view === "front") {
    // Snout, mouth and eyes.
    const sw = w * (fam === "spino" || fam === "raptor" || fam === "flyer" ? 0.52 : 0.72), sh = h * 0.5, sy = hy + h * 0.2;
    if (fierce) {
      const mo = `M ${-sw * 0.46},${sy + sh * 0.1} Q 0,${sy + sh * 0.95} ${sw * 0.46},${sy + sh * 0.1} Z`;
      out += `<path d="${mo}" fill="#3a0a0a"/>`;
    }
    out += e(0, sy, sw / 2, sh / 2, skin, p);
    out += `<ellipse cx="0" cy="${(sy + sh * 0.15).toFixed(1)}" rx="${(sw * 0.4).toFixed(1)}" ry="${(sh * 0.3).toFixed(1)}" fill="${p.belly}" opacity="0.6"/>`;
    for (const k of [-1, 1]) out += `<ellipse cx="${(k * sw * 0.18).toFixed(1)}" cy="${(sy - sh * 0.28).toFixed(1)}" rx="2.4" ry="1.6" fill="#1a0e08"/>`;
    const count = teethD.teeth.count || 0;
    if (fierce) {
      // Gaping jaw with two rows of teeth and blood.
      const jawY = sy + sh * 0.62;
      out += path(`M ${-sw * 0.45},${sy + sh * 0.2} Q 0,${jawY + sh * 0.55} ${sw * 0.45},${sy + sh * 0.2} Q 0,${jawY + sh * 0.2} ${-sw * 0.45},${sy + sh * 0.2} Z`, skin, p, 2.4);
      let t = "";
      const n = Math.min(8, 3 + Math.round(count * 0.5)), tl = 3 + teethD.teeth.sharp * 0.55;
      for (let i = 0; i < n; i++) {
        const x = -sw * 0.36 + (i * sw * 0.72) / (n - 1);
        t += `M ${x - 2.2},${sy + sh * 0.3} L ${x},${sy + sh * 0.3 + tl} L ${x + 2.2},${sy + sh * 0.3} Z `;
      }
      out += `<path d="${t}" fill="${p.toothFill}" stroke="${p.outline}" stroke-width="1.2"/>`;
      out += `<path d="M ${-sw * 0.2},${sy + sh * 0.35} q -2,8 0,13 q 2,-5 3,-13 Z M ${sw * 0.25},${sy + sh * 0.4} q -1,6 1,10 q 1,-4 2,-10 Z" fill="#7d0c0c"/>`;
    } else if (["ceratopsian", "hadrosaur", "flyer"].includes(fam) || count === 0) {
      out += path(`M ${-sw * 0.3},${sy + sh * 0.18} Q 0,${sy + sh * 0.7} ${sw * 0.3},${sy + sh * 0.18} Q 0,${sy + sh * 0.4} ${-sw * 0.3},${sy + sh * 0.18} Z`, p.clawFill, p, 2);
    } else {
      out += `<path d="M ${-sw * 0.32},${sy + sh * 0.22} Q 0,${sy + sh * 0.42} ${sw * 0.32},${sy + sh * 0.22}" fill="none" stroke="${p.outline}" stroke-width="2.4" stroke-linecap="round"/>`;
    }
    if (fam === "ceratopsian") {
      for (const k of [-1, 1]) out += path(`M ${k * w * 0.2 - 4},${hy - h * 0.25} Q ${k * w * 0.3},${hy - h * 0.9} ${k * w * 0.42},${hy - h * 1.15} Q ${k * w * 0.32},${hy - h * 0.7} ${k * w * 0.2 + 4},${hy - h * 0.25} Z`, p.clawFill, p, 2.2);
      out += path(`M -4,${sy - sh * 0.35} L 0,${sy - sh * 0.95} L 4,${sy - sh * 0.35} Z`, p.clawFill, p, 2);
    }
    // Eyes: set wide on herbivores, frontal and menacing on predators.
    const predator = PREDATORS.has(fam);
    const ex = w * (predator ? 0.28 : 0.36), ey = hy - h * 0.12, r = 4.2 * s;
    for (const k of [-1, 1]) {
      out += `<circle cx="${(k * ex).toFixed(1)}" cy="${ey.toFixed(1)}" r="${(r + 1.2).toFixed(1)}" fill="#150b06"/>
        <circle cx="${(k * ex).toFixed(1)}" cy="${ey.toFixed(1)}" r="${r.toFixed(1)}" fill="${predator ? (fierce ? "#e2560f" : "#e8a018") : "#5b3d22"}"/>
        ${predator ? `<ellipse cx="${(k * ex).toFixed(1)}" cy="${ey.toFixed(1)}" rx="${(r * 0.25).toFixed(1)}" ry="${(r * 0.8).toFixed(1)}" fill="#0d0603"/>` : `<circle cx="${(k * ex).toFixed(1)}" cy="${ey.toFixed(1)}" r="${(r * 0.5).toFixed(1)}" fill="#0d0603"/>`}
        <circle cx="${(k * ex - r * 0.3).toFixed(1)}" cy="${(ey - r * 0.35).toFixed(1)}" r="${(r * 0.22).toFixed(1)}" fill="#fff"/>`;
      if (predator) out += `<path d="M ${(k * ex - k * r * 1.8).toFixed(1)},${(ey - r * 1.5).toFixed(1)} L ${(k * ex + k * r * 1.4).toFixed(1)},${(ey - r * 0.6).toFixed(1)}" stroke="${p.outline}" stroke-width="3.2" stroke-linecap="round"/>`;
    }
  } else {
    // Back of the head: a darker crown and the ridge of the neck.
    out += `<ellipse cx="0" cy="${(hy - h * 0.1).toFixed(1)}" rx="${(w * 0.36).toFixed(1)}" ry="${(h * 0.3).toFixed(1)}" fill="${p.shade}" opacity="0.5"/>`;
    if (fam === "ceratopsian") for (const k of [-1, 1]) out += path(`M ${k * w * 0.18 - 4},${hy - h * 0.3} L ${k * w * 0.4},${hy - h * 1.05} L ${k * w * 0.18 + 4},${hy - h * 0.3} Z`, p.clawFill, p, 2);
  }
  return { svg: out, top: hy - h * 1.4 };
}

// ---------------------------------------------------------------- assembly
let uid = 0;

/** Front ("front") or back ("back") view of a hybrid. Returns { svg, viewBox, ground }. */
export function buildDinoView(build, view, options = {}) {
  const id = options.id || `dv${++uid}`;
  const D = (k) => DINOS[build[k]] || DINOS[0];
  const headD = D("head"), teethD = D("teeth"), frontD = D("frontLegs"), backLegsD = D("backLegs"), backD = D("back"), tailD = D("tail"), colorD = D("color");
  const p = makePalette(options.customColor || colorD.color, options.accentColor);
  p.clawFill = `url(#${id}-claw)`;
  p.toothFill = `url(#${id}-tooth)`;
  const fierce = isFierce(teethD);
  const posture = postureOf(backLegsD);
  const B = BODY[posture];

  const L = legs(posture, backLegsD, frontD, B, p, id, view);
  const dor = dorsal(backD, B, p, id, view);
  const hd = head(headD, teethD, B, p, id, view, fierce);
  const tl = tail(tailD, backD, B, p, id, view);

  const body = `${e(0, B.cy, B.w / 2, B.h / 2, `url(#${id}-body)`, p)}
    <ellipse cx="0" cy="${B.cy}" rx="${B.w / 2}" ry="${B.h / 2}" fill="url(#${id}-scales)" mask="url(#${id}-fade)"/>
    ${view === "front" ? `<ellipse cx="0" cy="${(B.cy + B.h * 0.12).toFixed(1)}" rx="${(B.w * 0.3).toFixed(1)}" ry="${(B.h * 0.34).toFixed(1)}" fill="url(#${id}-belly)"/>` : `<path d="M 0,${B.cy - B.h / 2 + 6} L 0,${B.cy + B.h * 0.3}" stroke="${p.deep}" stroke-width="3" opacity="0.4"/>`}
    <ellipse cx="${(-B.w * 0.15).toFixed(1)}" cy="${(B.cy - B.h * 0.28).toFixed(1)}" rx="${(B.w * 0.2).toFixed(1)}" ry="${(B.h * 0.1).toFixed(1)}" fill="#fff" opacity="0.18"/>`;

  // Draw order depends on which side faces the camera.
  const layers = view === "front"
    ? [tl, dor.svg, L.behind, body, L.front, hd.svg]
    : [hd.svg, L.behind, body, dor.onTop ? dor.svg : "", L.front, tl, dor.onTop ? "" : dor.svg];

  const defs = `
    <linearGradient id="${id}-body" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p.light}"/><stop offset="0.5" stop-color="${p.base}"/><stop offset="1" stop-color="${p.shade}"/></linearGradient>
    <linearGradient id="${id}-far" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p.shade}"/><stop offset="1" stop-color="${p.deep}"/></linearGradient>
    <linearGradient id="${id}-belly" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p.belly}"/><stop offset="1" stop-color="${p.bellyShade}"/></linearGradient>
    <linearGradient id="${id}-accent" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p.accentLight}"/><stop offset="1" stop-color="${p.accentShade}"/></linearGradient>
    <linearGradient id="${id}-wing" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${p.accentLight}"/><stop offset="1" stop-color="${p.shade}"/></linearGradient>
    <linearGradient id="${id}-claw" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fffaf0"/><stop offset="0.6" stop-color="${p.claw}"/><stop offset="1" stop-color="${p.clawShade}"/></linearGradient>
    <linearGradient id="${id}-tooth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fffdf6"/><stop offset="1" stop-color="#e4d6ae"/></linearGradient>
    <linearGradient id="${id}-fadegrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.85" stop-color="#000"/></linearGradient>
    <mask id="${id}-fade" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#${id}-fadegrad)"/></mask>
    <pattern id="${id}-scales" width="${PEBBLE_TILE}" height="${PEBBLE_TILE}" patternUnits="userSpaceOnUse">${pebbleTile(p)}</pattern>`;

  const halfW = posture === "flyer" ? 200 : posture === "marine" ? 120 : 110;
  const minY = Math.min(hd.top, B.cy - B.h / 2 - (backD.family === "spino" ? 110 : 40), posture === "flyer" ? B.cy - 110 : 0) - 10;
  const viewBox = [-halfW, Math.round(minY), halfW * 2, Math.round(10 - minY)];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox.join(" ")}"><defs>${defs}</defs>
    <ellipse cx="0" cy="-2" rx="${(B.w * 0.55).toFixed(1)}" ry="8" fill="rgba(0,0,0,0.25)"/>${layers.join("")}</svg>`;
  return { svg, viewBox, ground: 0, posture };
}
