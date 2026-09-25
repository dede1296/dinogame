// Modular vector dinosaur renderer.
//
// A dino is assembled from parts taken from different donor species (the hybrid
// mechanic). Every part is drawn in its own local space with its pivot at (0,0),
// then placed on a joint of the body, so parts can be animated independently
// (head bob, tail sway, walk cycle) both in SVG previews and in the game engine.
//
// Coordinates: the dino faces right, body centered at (0,0), y grows downward.

import { DINOS } from "../../../src/data/dinos.js";
import { makePalette } from "./palette.js";
import { tube, pt, along, seeded } from "./geometry.js";

const OUTLINE = 4;
const PREDATORS = new Set(["tyrant", "raptor", "spino", "marine"]);
const BIPED = new Set(["tyrant", "raptor", "spino", "hadrosaur"]);
const QUAD = new Set(["sauropod", "ceratopsian", "armored"]);

// ---------------------------------------------------------------- body
// One torso silhouette per posture. `top` approximates the back line as an ellipse
// (cx, cy, rx, ry) so dorsal features can be seated on it.
const BODIES = {
  // Teardrop: heavy chest, tapering into the tail like a real theropod.
  biped: {
    path: "M -100,-14 C -74,-46 -24,-64 26,-62 C 74,-60 102,-32 100,2 C 98,36 64,54 20,52 C -26,50 -70,28 -100,-14 Z",
    joints: { neck: [76, -32], tail: [-88, -12], hip: [-30, 26], shoulder: [60, 8] },
    top: [10, -6, 104, 56],
  },
  // Broad barrel for four-legged herbivores.
  quad: {
    path: "M -96,-2 C -96,-54 -40,-70 10,-68 C 64,-66 98,-38 98,-4 C 98,36 60,56 4,56 C -54,56 -96,42 -96,-2 Z",
    joints: { neck: [74, -30], tail: [-86, -8], hip: [-40, 30], shoulder: [50, 32] },
    top: [2, -4, 98, 64],
  },
  // Light, compact body for flyers.
  flyer: {
    path: "M -58,-6 C -54,-34 -18,-44 12,-42 C 44,-40 64,-24 64,-2 C 64,22 40,34 8,34 C -26,34 -60,22 -58,-6 Z",
    joints: { neck: [48, -22], tail: [-52, -4], hip: [-16, 22], shoulder: [26, -14] },
    top: [3, -4, 62, 40],
  },
  // Torpedo for marine reptiles.
  marine: {
    path: "M -104,-2 C -94,-40 -34,-56 18,-54 C 70,-52 102,-28 104,0 C 106,26 72,46 20,46 C -32,46 -94,34 -104,-2 Z",
    joints: { neck: [82, -24], tail: [-96, -2], hip: [-46, 30], shoulder: [44, 30] },
    top: [0, -2, 104, 54],
  },
};

// Height of the back at x, used to seat dorsal features on the body.
function backOf(body) {
  const [cx, cy, rx, ry] = body.top;
  return (x) => {
    const k = Math.min(1, Math.abs((x - cx) / rx));
    return cy - ry * Math.sqrt(1 - k * k);
  };
}

// ---------------------------------------------------------------- heads
// Each head is drawn at the end of its neck, facing right. `mouth` is the
// line where teeth are drawn: [xStart, xEnd, y].
const HEADS = {
  tyrant: {
    neck: { len: 34, angle: -38, w0: 46, w1: 38 },
    skull: "M -14,-8 C -12,-34 22,-44 56,-38 C 72,-35 84,-28 86,-14 L 84,2 L 18,6 C 2,6 -14,4 -14,-8 Z",
    jaw: "M -2,4 L 80,2 C 78,12 62,22 38,22 C 16,22 -2,16 -2,4 Z",
    mouth: [14, 80, 4],
    eye: [34, -22, 6.5],
    brow: "M 22,-30 Q 34,-37 46,-30",
    nostril: [76, -24],
    extras: (p) => `<path d="M 44,-36 Q 52,-46 60,-38" fill="${p.shade}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>`,
  },
  raptor: {
    neck: { len: 44, angle: -52, w0: 34, w1: 24 },
    skull: "M -10,-10 C -8,-28 16,-32 40,-26 C 56,-22 70,-14 74,-6 L 70,2 L 12,6 C 0,6 -12,2 -10,-10 Z",
    jaw: "M 4,4 L 68,1 C 62,10 44,14 26,14 C 12,14 2,10 4,4 Z",
    mouth: [12, 68, 3],
    eye: [26, -16, 5.5],
    brow: "M 16,-23 Q 26,-28 36,-22",
    nostril: [64, -12],
    extras: (p) => [0, 1, 2, 3].map((i) =>
      `<path d="M ${-4 + i * 8},${-24 + i * 2} Q ${-18 + i * 6},${-44 + i * 4} ${-30 + i * 6},${-38 + i * 5}" fill="none" stroke="${p.accent}" stroke-width="${5 - i}" stroke-linecap="round"/>`).join(""),
  },
  sauropod: {
    neck: { len: 150, angle: -68, w0: 44, w1: 22, curve: 22 },
    skull: "M -10,-6 C -10,-24 10,-30 28,-26 C 44,-22 52,-12 50,-2 C 48,6 40,8 30,8 L 4,8 C -6,8 -10,2 -10,-6 Z",
    jaw: "M 6,4 L 44,4 C 40,10 30,12 20,12 C 12,12 6,9 6,4 Z",
    mouth: [14, 44, 4],
    eye: [20, -14, 5],
    nostril: [30, -26],
    extras: (p) => `<path d="M 22,-26 Q 30,-36 38,-26" fill="${p.light}" stroke="${p.outline}" stroke-width="3"/>`,
  },
  ceratopsian: {
    neck: { len: 18, angle: -14, w0: 50, w1: 46 },
    frill: true,
    skull: "M -6,-18 C 6,-34 40,-34 58,-22 C 66,-16 74,-10 82,-2 L 76,8 C 60,12 30,12 8,10 C -4,8 -10,-6 -6,-18 Z",
    jaw: "M 10,8 L 72,6 C 66,16 46,20 28,18 C 16,17 8,14 10,8 Z",
    mouth: [18, 70, 7],
    eye: [30, -18, 5.5],
    nostril: [64, -12],
    beak: "M 68,-10 C 78,-8 88,0 86,6 C 80,10 72,10 66,8 Z",
    extras: (p) => `
      <path d="M 26,-28 C 30,-52 44,-66 62,-70 C 52,-58 44,-44 40,-28 Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M 16,-26 C 16,-44 24,-56 36,-60 C 30,-50 28,-38 28,-26 Z" fill="${p.clawShade}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M 60,-18 C 62,-30 68,-36 76,-38 C 72,-30 70,-22 70,-14 Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>`,
  },
  armored: {
    neck: { len: 16, angle: -8, w0: 46, w1: 40 },
    skull: "M -10,-12 C -6,-30 30,-34 54,-26 C 66,-22 72,-12 70,0 L 64,8 L 4,10 C -8,8 -14,0 -10,-12 Z",
    jaw: "M 6,8 L 64,6 C 58,14 42,16 28,16 C 16,16 6,13 6,8 Z",
    mouth: [14, 62, 7],
    eye: [30, -14, 5],
    nostril: [62, -14],
    extras: (p) => `
      ${[6, 22, 38].map((x) => `<ellipse cx="${x}" cy="${-27 + Math.abs(x - 22) * 0.12}" rx="8" ry="5" fill="${p.accent}" stroke="${p.outline}" stroke-width="2.5"/>`).join("")}
      <path d="M -4,-18 L -20,-26 L -8,-8 Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M -2,2 L -18,10 L -4,10 Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>`,
  },
  hadrosaur: {
    neck: { len: 50, angle: -50, w0: 40, w1: 30 },
    skull: "M -8,-14 C -4,-30 22,-34 42,-26 C 52,-22 60,-16 70,-12 C 84,-8 92,-2 90,4 C 88,10 78,10 70,8 L 8,10 C -4,8 -12,-2 -8,-14 Z",
    jaw: "M 10,8 L 72,6 C 66,14 44,18 28,16 C 16,15 8,12 10,8 Z",
    mouth: [18, 70, 7],
    eye: [26, -16, 5.5],
    nostril: [80, -4],
    extras: (p) => `<path d="${tube([[20, -28], [0, -46], [-26, -56], [-46, -54]], [16, 15, 13, 11])}" fill="${p.accent}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M 14,-40 Q -10,-54 -38,-54" fill="none" stroke="${p.accentLight}" stroke-width="3" stroke-linecap="round" opacity="0.7"/>`,
  },
  spino: {
    neck: { len: 50, angle: -46, w0: 42, w1: 30 },
    skull: "M -10,-12 C -8,-28 18,-32 38,-24 L 98,-10 C 104,-8 104,0 98,2 L 12,6 C 0,6 -12,0 -10,-12 Z",
    jaw: "M 6,4 L 96,2 C 90,10 60,12 30,12 C 14,12 4,9 6,4 Z",
    mouth: [14, 96, 3],
    eye: [22, -16, 5.5],
    brow: "M 12,-22 Q 22,-28 32,-22",
    nostril: [70, -14],
    extras: (p) => `<path d="M 30,-26 Q 38,-38 48,-24" fill="${p.accent}" stroke="${p.outline}" stroke-width="3"/>`,
  },
  flyer: {
    neck: { len: 54, angle: -56, w0: 30, w1: 22 },
    skull: "M -8,-8 C -6,-22 12,-26 30,-20 L 104,-4 C 106,-2 106,2 102,3 L 26,8 C 8,10 -10,4 -8,-8 Z",
    jaw: "M 20,5 L 100,2 C 80,8 50,11 30,11 C 22,11 18,8 20,5 Z",
    mouth: [24, 96, 4],
    eye: [16, -12, 5],
    nostril: [70, -8],
    extras: (p) => `<path d="M 2,-16 C -20,-40 -48,-58 -70,-62 C -50,-40 -24,-18 -4,-4 Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>`,
  },
  marine: {
    neck: { len: 36, angle: -18, w0: 48, w1: 40 },
    skull: "M -12,-14 C -8,-30 30,-32 62,-22 C 78,-16 90,-8 92,0 L 84,6 L 4,10 C -10,8 -16,-2 -12,-14 Z",
    jaw: "M 4,8 L 86,4 C 78,14 52,20 30,20 C 14,20 2,15 4,8 Z",
    mouth: [12, 84, 6],
    eye: [30, -16, 6],
    brow: "M 20,-24 Q 30,-30 40,-24",
    nostril: [78, -10],
    extras: () => "",
  },
};

function teethMarkup(head, teeth, p) {
  const count = Math.round((teeth.count || 0) * 1.1);
  if (!count) return "";
  const [x0, x1, y] = head.mouth;
  const h = 2.5 + teeth.sharp * 0.6;
  const w = Math.min(7, (x1 - x0) / (count + 1));
  let d = "";
  for (let i = 0; i < count; i++) {
    const x = x0 + ((i + 1) * (x1 - x0)) / (count + 1);
    d += `M ${x - w / 2},${y} L ${x},${y + h} L ${x + w / 2},${y} Z `;
    if (teeth.sharp > 5 && i % 2) d += `M ${x - w / 2},${y + 2} L ${x},${y + 2 - h * 0.7} L ${x + w / 2},${y + 2} Z `;
  }
  return `<path d="${d}" fill="${p.toothFill}" stroke="${p.outline}" stroke-width="1.5" stroke-linejoin="round"/>`;
}

function eyeMarkup(head, family, p, id) {
  const [x, y, r] = head.eye;
  const predator = PREDATORS.has(family);
  const pupil = predator
    ? `<ellipse cx="${x + 1}" cy="${y}" rx="${r * 0.28}" ry="${r * 0.8}" fill="#120904"/>`
    : `<circle cx="${x + 1}" cy="${y}" r="${r * 0.55}" fill="#120904"/>`;
  const iris = predator ? "#f2b11a" : "#6b4a2a";
  return `
    <circle cx="${x}" cy="${y}" r="${r + 1.5}" fill="${p.outline}"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="${p.eyeWhite}"/>
    <circle cx="${x + 1}" cy="${y}" r="${r * 0.72}" fill="${iris}"/>
    ${pupil}
    <circle cx="${x - r * 0.25}" cy="${y - r * 0.35}" r="${r * 0.25}" fill="#fff"/>
    <circle cx="${x + r * 0.35}" cy="${y + r * 0.35}" r="${r * 0.12}" fill="#fff" opacity="0.7"/>
    <path d="M ${x - r - 1.5},${y - (predator ? r * 0.15 : r * 0.45)} Q ${x},${y - r * 1.75} ${x + r + 1.5},${y - (predator ? r * 0.05 : r * 0.45)} Q ${x},${y - (predator ? r * 0.55 : r * 1.05)} ${x - r - 1.5},${y - (predator ? r * 0.15 : r * 0.45)} Z" fill="${p.shade}" stroke="${p.outline}" stroke-width="2" stroke-linejoin="round"/>
    <path d="M ${x - r * 0.9},${y + r * 1.05} Q ${x},${y + r * 1.45} ${x + r * 0.9},${y + r * 1.05}" fill="none" stroke="${p.shade}" stroke-width="1.6" opacity="0.8"/>
    ${head.brow ? `<path d="${head.brow}" fill="none" stroke="${p.outline}" stroke-width="4" stroke-linecap="round"/>` : ""}`;
}

function frillMarkup(p, id) {
  // Fan behind the head with a spiked rim.
  let rim = "";
  for (let i = 0; i <= 8; i++) {
    const a = (-150 + i * 17) * (Math.PI / 180);
    const r1 = 58, r2 = 70;
    const x = -4 + Math.cos(a) * r1, y = -16 + Math.sin(a) * r1;
    const xs = -4 + Math.cos(a) * r2, ys = -16 + Math.sin(a) * r2;
    rim += `<path d="M ${x - 5},${y} L ${xs},${ys} L ${x + 5},${y + 3} Z" fill="${p.accentLight}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>`;
  }
  return `${rim}
    <path d="M 24,-10 C 10,-60 -30,-78 -60,-58 C -74,-44 -70,-10 -46,6 C -26,16 8,8 24,-10 Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    <path d="M 4,-16 C -6,-46 -30,-58 -48,-46" fill="none" stroke="${p.accentShade}" stroke-width="3" opacity="0.6"/>
    <circle cx="-30" cy="-30" r="7" fill="${p.accentShade}" opacity="0.7"/>`;
}

// Neck + head as one part, pivoting on the body's neck joint.
function headPart(headDino, teethDino, p, id) {
  const family = headDino.family;
  const head = HEADS[family] || HEADS.tyrant;
  const s = 0.82 + headDino.head.size * 0.04;
  const { len, angle, w0, w1, curve = 0 } = head.neck;
  const a = (angle * Math.PI) / 180;
  const end = [Math.cos(a) * len, Math.sin(a) * len];
  const mid = [end[0] * 0.5 - curve, end[1] * 0.5];
  const neck = len > 20
    ? `<path d="${tube([[0, 0], mid, end], [w0, (w0 + w1) / 2, w1])}" fill="url(#${id}-body)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
       <path d="${tube([[6, 8], [mid[0] + 6, mid[1] + 6], [end[0] + 6, end[1] + 8]], [w0 * 0.45, w0 * 0.35, w1 * 0.4])}" fill="${p.belly}" opacity="0.85"/>`
    : "";

  const inner = `
    ${head.frill ? frillMarkup(p, id) : ""}
    <path d="${head.jaw}" fill="url(#${id}-body)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    <path d="${head.jaw}" fill="${p.belly}" opacity="0.55"/>
    <path d="M ${head.mouth[0]},${head.mouth[2]} L ${head.mouth[1]},${head.mouth[2] - 1}" stroke="${p.mouth}" stroke-width="5" stroke-linecap="round"/>
    ${teethMarkup(head, teethDino.teeth, p)}
    <path d="${head.skull}" fill="url(#${id}-body)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    ${head.beak ? `<path d="${head.beak}" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>` : ""}
    ${head.extras(p)}
    <circle cx="${head.nostril[0]}" cy="${head.nostril[1]}" r="2.2" fill="${p.outline}"/>
    ${eyeMarkup(head, family, p, id)}
    <path d="${head.skull}" fill="none" stroke="#fff" stroke-width="2" opacity="0.18" transform="translate(0,3) scale(0.96)"/>`;

  return {
    svg: `${neck}<g transform="translate(${pt(end)}) scale(${s.toFixed(3)})">${inner}</g>`,
    reach: { x: end[0] + 100 * s, y: end[1] - 80 * s },
  };
}

// ---------------------------------------------------------------- tails
function tailPart(tailDino, backDino, p, id) {
  const family = tailDino.family;
  const L = 70 + tailDino.tail.length * 11;
  const thick = 40 + tailDino.tail.power * 1.6;
  const curl = family === "sauropod" ? 28 : family === "marine" ? 4 : -10;
  let pts = [[10, 0], [-L * 0.25, -8], [-L * 0.5, -12 + curl * 0.2], [-L * 0.76, -8 + curl * 0.6], [-L, curl]];
  let ws = [thick * 1.15, thick * 0.82, thick * 0.55, thick * 0.3, 5];
  if (family === "flyer") { pts = [[4, 0], [-40, 4], [-80, 10]]; ws = [22, 10, 3]; }

  const tip = pts[pts.length - 1];
  let ornament = "";
  if (family === "armored" && tailDino.back.spikes >= 9) {
    ornament = [0, 1, 2, 3].map((i) => {
      const q = along(pts, 0.72 + i * 0.07);
      const dir = i % 2 ? 1 : -1;
      return `<path d="M ${q.x - 5},${q.y} L ${q.x - 14},${q.y + dir * 34} L ${q.x + 5},${q.y} Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>`;
    }).join("");
  } else if (family === "armored" && tailDino.tail.power >= 9) {
    ornament = `<path d="M ${tip[0] + 12},${tip[1] - 16} C ${tip[0] - 14},${tip[1] - 24} ${tip[0] - 26},${tip[1] - 8} ${tip[0] - 22},${tip[1] + 4} C ${tip[0] - 18},${tip[1] + 20} ${tip[0] + 6},${tip[1] + 22} ${tip[0] + 14},${tip[1] + 12} Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      <path d="M ${tip[0] - 6},${tip[1] - 10} Q ${tip[0] - 14},${tip[1]} ${tip[0] - 6},${tip[1] + 10}" fill="none" stroke="${p.accentShade}" stroke-width="3"/>`;
  } else if (family === "marine") {
    ornament = `<path d="M ${tip[0] + 16},${tip[1]} C ${tip[0] - 4},${tip[1] - 30} ${tip[0] - 20},${tip[1] - 44} ${tip[0] - 30},${tip[1] - 46} C ${tip[0] - 24},${tip[1] - 20} ${tip[0] - 24},${tip[1] + 14} ${tip[0] - 20},${tip[1] + 30} C ${tip[0] - 6},${tip[1] + 24} ${tip[0] + 8},${tip[1] + 12} ${tip[0] + 16},${tip[1]} Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>`;
  } else if (family === "raptor") {
    ornament = [0, 1, 2, 3, 4].map((i) => {
      const q = along(pts, 0.55 + i * 0.1);
      return `<path d="M ${q.x},${q.y - 6} q -10,-16 -24,-18 q 10,10 12,20 Z M ${q.x},${q.y + 6} q -10,16 -24,18 q 10,-10 12,-20 Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="2" stroke-linejoin="round"/>`;
    }).join("");
  } else if (family === "flyer") {
    ornament = `<path d="M ${tip[0] + 4},${tip[1]} l -14,-10 l -10,10 l 10,10 Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>`;
  }

  const underside = tube(
    pts.map(([x, y], i) => [x, y + ws[i] * 0.22]),
    ws.map((w) => w * 0.45),
  );
  return {
    svg: `${family === "raptor" ? ornament : ""}
      <path d="${tube(pts, ws)}" fill="url(#${id}-body)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      <path d="${underside}" fill="${p.belly}" opacity="0.7"/>
      ${family !== "raptor" ? ornament : ""}`,
    reach: -L - 40,
  };
}

// ---------------------------------------------------------------- limbs
function claws(x, y, n, len, p, up = false) {
  let d = "";
  for (let i = 0; i < n; i++) {
    const cx = x + i * 7;
    d += up
      ? `M ${cx},${y} q 6,-${len} ${len * 0.9},-${len * 0.4} q -4,${len * 0.2} -${len * 0.5},${len * 0.6} Z `
      : `M ${cx},${y - 3} q ${len},0 ${len * 1.1},${len * 0.6} q -${len * 0.6},-${len * 0.1} -${len * 1.1},${len * 0.1} Z `;
  }
  return `<path d="${d}" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="2" stroke-linejoin="round"/>`;
}

// Hind leg, pivot at the hip. Returns markup and its height (hip to ground).
function hindLeg(dino, posture, p, id, far) {
  const fill = `url(#${id}-${far ? "far" : "limb"})`;
  const pw = dino.backLegs.power;
  const family = dino.family;
  if (posture === "quad") {
    const w = 30 + pw * 1.4;
    return {
      h: 60,
      svg: `<path d="${tube([[0, -8], [0, 22], [-2, 50]], [w + 10, w, w * 0.9])}" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
        <path d="M ${-w * 0.5},52 C ${-w * 0.55},62 ${w * 0.5},62 ${w * 0.5},52 Z" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
        ${[0, 1, 2].map((i) => `<ellipse cx="${-w * 0.25 + i * w * 0.28}" cy="58" rx="4.5" ry="3.5" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="1.8"/>`).join("")}`,
    };
  }
  if (posture === "flyer") {
    return {
      h: 40,
      svg: `<path d="${tube([[0, -4], [4, 18], [0, 34]], [18, 12, 8])}" fill="${fill}" stroke="${p.outline}" stroke-width="3" stroke-linejoin="round"/>
        ${claws(0, 38, 3, 8, p)}`,
    };
  }
  if (posture === "marine") {
    return {
      h: 26,
      svg: `<path d="M -10,-6 C 10,-8 24,8 28,26 C 20,34 0,30 -10,18 C -18,10 -18,-2 -10,-6 Z" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>`,
    };
  }
  // Biped
  const slender = family === "raptor";
  const thigh = slender ? [34, 28, 18] : [48 + pw, 40 + pw, 24];
  const svg = `
    <path d="${tube([[0, -10], [4, 16], [-4, 40]], thigh)}" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    <path d="${tube([[-4, 38], [4, 60], [2, 76]], slender ? [14, 11, 10] : [22, 16, 14])}" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    <path d="M -10,74 C -12,82 -8,86 0,86 L 26,86 C 34,86 34,78 26,76 L 8,72 Z" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    ${claws(18, 82, 2, 9, p)}
    ${slender ? `<path d="M 4,74 C -2,62 8,54 18,60 C 12,60 8,66 10,74 Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="2.2" stroke-linejoin="round"/>` : ""}`;
  return { h: 86, svg };
}

// Front limb, pivot at the shoulder.
function frontLimb(dino, posture, p, id, far, height) {
  const fill = `url(#${id}-${far ? "far" : "limb"})`;
  const family = dino.family;
  const { power, reach } = dino.frontLegs;
  if (posture === "quad") {
    const w = 26 + power * 1.3;
    const h = height - 2;
    return `<path d="${tube([[0, -6], [2, h * 0.45], [0, h - 8]], [w + 6, w, w * 0.9])}" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      <path d="M ${-w * 0.5},${h - 6} C ${-w * 0.55},${h + 4} ${w * 0.5},${h + 4} ${w * 0.5},${h - 6} Z" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      ${[0, 1, 2].map((i) => `<ellipse cx="${-w * 0.25 + i * w * 0.28}" cy="${h}" rx="4" ry="3.2" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="1.8"/>`).join("")}`;
  }
  if (posture === "flyer") {
    // Raised membrane wing: arm up to the wrist, long finger sweeping back to the tip,
    // trailing edge scalloped back down to the hip.
    const s = 0.62 + reach * 0.03;
    const W = (x, y) => `${(x * s).toFixed(1)},${(y * s).toFixed(1)}`;
    return `<path d="M ${W(0, 0)} C ${W(8, -30)} ${W(18, -52)} ${W(22, -64)} C ${W(-20, -104)} ${W(-100, -124)} ${W(-178, -112)} C ${W(-150, -96)} ${W(-128, -70)} ${W(-120, -58)} C ${W(-98, -52)} ${W(-80, -30)} ${W(-74, -16)} C ${W(-58, -10)} ${W(-46, 8)} ${W(-40, 34)} C ${W(-24, 24)} ${W(-10, 12)} ${W(0, 0)} Z" fill="url(#${id}-wing)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      <path d="M ${W(0, 0)} C ${W(8, -30)} ${W(18, -52)} ${W(22, -64)} C ${W(-20, -104)} ${W(-100, -124)} ${W(-178, -112)}" fill="none" stroke="${p.outline}" stroke-width="6" stroke-linecap="round"/>
      <path d="M ${W(16, -60)} Q ${W(-50, -80)} ${W(-120, -58)} M ${W(12, -54)} Q ${W(-30, -40)} ${W(-74, -16)}" fill="none" stroke="${p.shade}" stroke-width="2.5" opacity="0.6"/>
      ${claws(22 * s, -64 * s, 3, 6, p, true)}`;
  }
  if (posture === "marine") {
    return `<path d="M -8,-6 C 14,-6 32,14 36,40 C 26,46 6,40 -6,26 C -14,14 -16,0 -8,-6 Z" fill="${fill}" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>`;
  }
  // Biped arms
  if (family === "tyrant") {
    return `<path d="${tube([[0, 0], [10, 10], [18, 16]], [16, 11, 9])}" fill="${fill}" stroke="${p.outline}" stroke-width="3.5" stroke-linejoin="round"/>
      ${claws(20, 18, 2, 6, p)}`;
  }
  const l = 26 + reach * 3;
  const clawLen = family === "raptor" || family === "spino" ? 6 + reach * 1.3 : 7;
  return `<path d="${tube([[0, 0], [10, l * 0.5], [22, l * 0.8]], [20 + power, 15, 11])}" fill="${fill}" stroke="${p.outline}" stroke-width="3.5" stroke-linejoin="round"/>
    ${claws(22, l * 0.8 + 6, 3, clawLen, p)}`;
}

// ---------------------------------------------------------------- dorsal
function dorsalPart(backDino, p, id, rand, backY) {
  const { family } = backDino;
  const { spikes, armor } = backDino.back;
  if (family === "spino") {
    const h = 40 + spikes * 6;
    const xs = [-56, -36, -16, 4, 24, 44];
    const tops = xs.map((x, i) => [x, backY(x) - h * Math.sin(((i + 0.6) / xs.length) * Math.PI) - 4]);
    const d = `M -66,${backY(-66) + 12} ` + tops.map(([x, y], i) => `Q ${x - 6},${y - 10} ${x},${y} ${i < tops.length - 1 ? `Q ${x + 6},${y + 8} ${(x + tops[i + 1][0]) / 2},${(y + tops[i + 1][1]) / 2 + 6}` : ""}`).join(" ") + ` L 60,${backY(60) + 12} Z`;
    const ribs = tops.map(([x, y]) => `M ${x},${y + 4} L ${x + 2},${backY(x) + 8}`).join(" ");
    return { svg: `<path d="${d}" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
      <path d="${ribs}" stroke="${p.accentShade}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>`, height: h };
  }
  if (family === "armored" && spikes >= 9) {
    const plates = [-52, -30, -8, 14, 36].map((x, i) => {
      const s = 16 + (i === 2 ? 14 : i === 1 || i === 3 ? 10 : 2) + armor * 0.4;
      const y = backY(x) + 8;
      return `<path d="M ${x - s * 0.6},${y} C ${x - s * 0.7},${y - s} ${x - s * 0.2},${y - s * 1.6} ${x + 2},${y - s * 1.7} C ${x + s * 0.4},${y - s * 1.4} ${x + s * 0.8},${y - s * 0.8} ${x + s * 0.6},${y} Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
        <path d="M ${x},${y - 4} L ${x + 1},${y - s * 1.3}" stroke="${p.accentShade}" stroke-width="2.5" opacity="0.7"/>`;
    });
    return { svg: plates.join(""), height: 50 };
  }
  if (family === "armored" || (family === "ceratopsian" && armor >= 8)) {
    const bumps = [-64, -44, -24, -4, 16, 36, 56].map((x) => {
      const y = backY(x) + 6;
      return `<path d="M ${x - 9},${y} C ${x - 9},${y - 12} ${x + 9},${y - 12} ${x + 9},${y} Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="3"/>
        ${spikes >= 6 ? `<path d="M ${x - 4},${y - 8} L ${x},${y - 20} L ${x + 4},${y - 8} Z" fill="${p.clawFill}" stroke="${p.outline}" stroke-width="2.2" stroke-linejoin="round"/>` : ""}`;
    });
    return { svg: bumps.join(""), height: 20 };
  }
  if (family === "sauropod" && spikes >= 6) {
    const spines = [-40, -24, -8, 8, 24, 40, 56].map((x) => {
      const y = backY(x) + 6;
      return `<path d="M ${x - 3},${y} L ${x + 4},${y - 24 - spikes} L ${x + 5},${y} Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>`;
    });
    return { svg: spines.join(""), height: 34 };
  }
  if (family === "raptor") {
    const tufts = [-60, -44, -28, -12, 4, 20, 36].map((x) => {
      const y = backY(x) + 6;
      const len = 14 + rand() * 8;
      return `<path d="M ${x - 6},${y} Q ${x - 10},${y - len} ${x - 18},${y - len - 4} Q ${x - 4},${y - len * 0.6} ${x + 6},${y} Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="2" stroke-linejoin="round"/>`;
    });
    return { svg: tufts.join(""), height: 24 };
  }
  if ((family === "tyrant" && spikes >= 4) || family === "marine") {
    const n = family === "marine" ? 1 : 6;
    if (family === "marine") {
      return { svg: `<path d="M -30,${backY(-30) + 8} C -20,${backY(-10) - 30} 0,${backY(0) - 40} 16,${backY(10) - 34} C 12,${backY(10) - 14} 16,${backY(20)} 20,${backY(20) + 8} Z" fill="url(#${id}-accent)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>`, height: 40 };
    }
    const ridge = Array.from({ length: n }, (_, i) => {
      const x = -50 + i * 18;
      const y = backY(x) + 6;
      const h = 10 + spikes * 1.5;
      return `<path d="M ${x - 7},${y} L ${x - 2},${y - h} L ${x + 7},${y} Z" fill="${p.accent}" stroke="${p.outline}" stroke-width="2.5" stroke-linejoin="round"/>`;
    });
    return { svg: ridge.join(""), height: 26 };
  }
  return { svg: "", height: 0 };
}

// ---------------------------------------------------------------- patterns
function patternMarkup(pattern, p, id, rand) {
  if (!pattern || pattern === "none") return "";
  let shapes = "";
  if (pattern === "stripes") {
    for (let x = -80; x < 90; x += 22) shapes += `<path d="M ${x},-70 Q ${x + 10},-20 ${x - 4},20" stroke="${p.shade}" stroke-width="9" fill="none" stroke-linecap="round" opacity="0.55"/>`;
  } else if (pattern === "spots") {
    for (let i = 0; i < 16; i++) shapes += `<circle cx="${-80 + rand() * 170}" cy="${-60 + rand() * 60}" r="${4 + rand() * 6}" fill="${p.shade}" opacity="0.55"/>`;
  } else if (pattern === "camo") {
    for (let i = 0; i < 9; i++) shapes += `<ellipse cx="${-80 + rand() * 170}" cy="${-55 + rand() * 70}" rx="${12 + rand() * 12}" ry="${7 + rand() * 7}" fill="${i % 2 ? p.shade : p.light}" opacity="0.5"/>`;
  }
  return `<g clip-path="url(#${id}-clip)">${shapes}</g>`;
}

// ---------------------------------------------------------------- assembly
function postureOf(backLegsDino) {
  if (BIPED.has(backLegsDino.family)) return "biped";
  if (QUAD.has(backLegsDino.family)) return "quad";
  return backLegsDino.family === "flyer" ? "flyer" : "marine";
}

let uid = 0;

// Adds scales, volume shading and skin grain on top of every skin-colored shape
// (fills using the body/limb/far gradients) of a part.
const SKIN_FILL = /<path d="([^"]+)" fill="url\(#([\w-]+)-(body|limb|far)\)"([^>]*)\/>/g;
function skin(svg, id) {
  return svg.replace(SKIN_FILL, (match, d) => `${match}
    <path d="${d}" fill="url(#${id}-scales)" mask="url(#${id}-fade)"/>
    <path d="${d}" fill="url(#${id}-ao)"/>
    <path d="${d}" fill="#000" filter="url(#${id}-grain)" opacity="0.2"/>`);
}

/**
 * Builds the vector art for a hybrid.
 * @param build { head, teeth, frontLegs, backLegs, back, tail, color } — indices into DINOS
 * @param options { pattern, customColor, id }
 * Returns { svg, parts, joints, viewBox, ground } where `parts` holds each piece's
 * markup in its own pivot space (for the game engine's rig).
 */
export function buildDino(build, options = {}) {
  const id = options.id || `dino${++uid}`;
  const D = (k) => DINOS[build[k]] || DINOS[0];
  const headD = D("head"), teethD = D("teeth"), frontD = D("frontLegs"), backLegsD = D("backLegs");
  const backD = D("back"), tailD = D("tail"), colorD = D("color");
  const p = makePalette(options.customColor || colorD.color, options.accentColor);
  p.clawFill = `url(#${id}-claw)`;
  p.toothFill = `url(#${id}-tooth)`;
  const rand = seeded(Object.values(build).reduce((a, v, i) => a * 31 + (v || 0) * (i + 7), 17));
  const posture = postureOf(backLegsD);

  const B = BODIES[posture];
  const joints = B.joints;
  const hind = hindLeg(backLegsD, posture, p, id, false);
  const hindFar = hindLeg(backLegsD, posture, p, id, true);
  const ground = joints.hip[1] + hind.h;
  const shoulderToGround = ground - joints.shoulder[1];

  const head = headPart(headD, teethD, p, id);
  const tail = tailPart(tailD, backD, p, id);
  const dorsal = posture === "flyer" ? { svg: "", height: 0 } : dorsalPart(backD, p, id, rand, backOf(B));
  const front = frontLimb(frontD, posture, p, id, false, shoulderToGround);
  const frontFar = frontLimb(frontD, posture, p, id, true, shoulderToGround);

  const [bcx, bcy, brx, bry] = B.top;
  // Natural mottling: darker blotches concentrated on the back.
  let mottle = "";
  for (let i = 0; i < 14; i++) {
    const x = bcx - brx * 0.8 + rand() * brx * 1.6;
    const y = bcy - bry * (0.35 + rand() * 0.55);
    mottle += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(3 + rand() * 7).toFixed(1)}" ry="${(2 + rand() * 4).toFixed(1)}" fill="${p.deep}" opacity="${(0.12 + rand() * 0.14).toFixed(2)}"/>`;
  }
  // Belly plates: transverse bands following the underside.
  let plates = "";
  for (let k = -0.62; k <= 0.66; k += 0.11) {
    const x = bcx + 12 + k * brx;
    const y = bcy + bry * (0.5 + 0.1 * Math.cos(k * 2.2));
    plates += `<path d="M ${(x - 2).toFixed(1)},${(y - 4).toFixed(1)} Q ${(x + 3).toFixed(1)},${(y + bry * 0.3).toFixed(1)} ${(x - 1).toFixed(1)},${(y + bry * 0.6).toFixed(1)}" stroke="${p.bellyShade}" stroke-width="1.6" fill="none" opacity="0.7"/>`;
  }
  const [hx, hy] = joints.hip, [sx, sy] = joints.shoulder;
  const body = `
    <path d="${B.path}" fill="url(#${id}-body)" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>
    <g clip-path="url(#${id}-clip)">
      <ellipse cx="${bcx}" cy="${bcy - bry * 0.75}" rx="${brx * 0.95}" ry="${bry * 0.45}" fill="${p.shade}" opacity="0.32"/>
      ${mottle}
      <ellipse cx="${bcx + 12}" cy="${bcy + bry * 0.8}" rx="${brx * 0.9}" ry="${bry * 0.52}" fill="url(#${id}-belly)"/>
      ${plates}
      <path d="${B.path}" fill="url(#${id}-scales)" mask="url(#${id}-fade)"/>
      <ellipse cx="${hx}" cy="${hy - 4}" rx="34" ry="30" fill="url(#${id}-joint)"/>
      <ellipse cx="${sx}" cy="${sy}" rx="26" ry="24" fill="url(#${id}-joint)"/>
      <path d="M ${hx + 22},${hy - 26} q 6,10 2,22 M ${hx + 28},${hy - 20} q 5,8 1,16" stroke="${p.deep}" stroke-width="1.8" fill="none" opacity="0.45" stroke-linecap="round"/>
      <path d="${B.path}" fill="url(#${id}-ao)"/>
      <path d="${B.path}" fill="#000" filter="url(#${id}-grain)" opacity="0.22"/>
    </g>
    ${patternMarkup(options.pattern, p, id, rand)}
    <ellipse cx="${bcx - 8}" cy="${bcy - bry * 0.66}" rx="${brx * 0.5}" ry="${bry * 0.16}" fill="#fff" opacity="0.18"/>
    <ellipse cx="${bcx - 22}" cy="${bcy - bry * 0.74}" rx="${brx * 0.2}" ry="${bry * 0.06}" fill="#fff" opacity="0.25"/>
    <path d="${B.path}" fill="none" stroke="${p.outline}" stroke-width="${OUTLINE}" stroke-linejoin="round"/>`;

  const defs = `
    <linearGradient id="${id}-body" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${p.light}"/><stop offset="0.45" stop-color="${p.base}"/><stop offset="1" stop-color="${p.shade}"/>
    </linearGradient>
    <linearGradient id="${id}-limb" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${p.base}"/><stop offset="1" stop-color="${p.shade}"/>
    </linearGradient>
    <linearGradient id="${id}-far" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${p.shade}"/><stop offset="1" stop-color="${p.deep}"/>
    </linearGradient>
    <linearGradient id="${id}-belly" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${p.belly}"/><stop offset="1" stop-color="${p.bellyShade}"/>
    </linearGradient>
    <linearGradient id="${id}-accent" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${p.accentLight}"/><stop offset="1" stop-color="${p.accentShade}"/>
    </linearGradient>
    <linearGradient id="${id}-wing" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${p.accentLight}" stop-opacity="0.95"/><stop offset="1" stop-color="${p.shade}" stop-opacity="0.95"/>
    </linearGradient>
    <clipPath id="${id}-clip"><path d="${B.path}"/></clipPath>
    <pattern id="${id}-scales" width="16" height="12" patternUnits="userSpaceOnUse">
      <path d="M 0,12 a 8,7 0 0 1 16,0 M -8,6 a 8,7 0 0 1 16,0 M 8,6 a 8,7 0 0 1 16,0" fill="none" stroke="${p.deep}" stroke-width="1.4" opacity="0.32"/>
      <path d="M 3,10.5 a 5,4.5 0 0 1 10,0 M -5,4.5 a 5,4.5 0 0 1 10,0 M 11,4.5 a 5,4.5 0 0 1 10,0" fill="none" stroke="#fff" stroke-width="1" opacity="0.14"/>
    </pattern>
    <linearGradient id="${id}-fadegrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fff"/><stop offset="0.45" stop-color="#fff"/><stop offset="0.8" stop-color="#000"/>
    </linearGradient>
    <mask id="${id}-fade" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#${id}-fadegrad)"/></mask>
    <linearGradient id="${id}-ao" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.3"/>
    </linearGradient>
    <radialGradient id="${id}-joint">
      <stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0.06"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/>
    </radialGradient>
    <linearGradient id="${id}-claw" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fffaf0"/><stop offset="0.6" stop-color="${p.claw}"/><stop offset="1" stop-color="${p.clawShade}"/>
    </linearGradient>
    <linearGradient id="${id}-tooth" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fffdf6"/><stop offset="1" stop-color="#e4d6ae"/>
    </linearGradient>
    <filter id="${id}-grain" x="0" y="0" width="100%" height="100%">
      <feTurbulence type="fractalNoise" baseFrequency="0.22" numOctaves="3" seed="${Math.floor(rand() * 999)}" result="noise"/>
      <feColorMatrix in="noise" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.2 1.25" result="speckle"/>
      <feComposite in="speckle" in2="SourceAlpha" operator="in"/>
    </filter>`;

  const parts = {
    dorsal: { svg: dorsal.svg, at: [0, 0] },
    hindFar: { svg: skin(hindFar.svg, id), at: [joints.hip[0] + 16, joints.hip[1] - 6] },
    frontFar: { svg: skin(frontFar, id), at: [joints.shoulder[0] + 14, joints.shoulder[1] - 6] },
    tail: { svg: skin(tail.svg, id), at: joints.tail },
    body: { svg: body, at: [0, 0] },
    hind: { svg: skin(hind.svg, id), at: joints.hip },
    head: { svg: skin(head.svg, id), at: joints.neck },
    front: { svg: skin(front, id), at: joints.shoulder },
  };
  // Flyers fold the far wing behind the body; drop the duplicate for other postures' arms.
  const order = posture === "flyer"
    ? ["frontFar", "hindFar", "tail", "dorsal", "body", "hind", "head", "front"]
    : ["hindFar", "frontFar", "dorsal", "tail", "body", "hind", "head", "front"];

  const minX = Math.min(joints.tail[0] + tail.reach, -120);
  const maxX = Math.max(joints.neck[0] + head.reach.x, 130);
  const minY = Math.min(joints.neck[1] + head.reach.y, -80 - dorsal.height, posture === "flyer" ? -200 : 0);
  const maxY = ground + 8;
  const viewBox = [minX, minY, maxX - minX, maxY - minY].map((v) => Math.round(v));

  const layers = order.map((k) => `<g class="part part-${k}" transform="translate(${pt(parts[k].at)})"><g class="anim-${k}">${parts[k].svg}</g></g>`).join("");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox.join(" ")}"><defs>${defs}</defs>${layers}</svg>`;

  return { id, svg, defs, parts, order, joints, viewBox, ground, posture, palette: p };
}
