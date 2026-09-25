import { shadeColor } from "../utils/color.js";

// ============ DINO SVG (parametric) ============
// ============ PIXEL ART SPRITE SYSTEM ============
// Sprite encoding: each character represents one pixel
// . = transparent
// o = outline (very dark)    b = body base        d = dark shading
// l = light highlight        u = belly (lighter)  w = eye white
// p = pupil (black)          t = teeth/bone       m = mouth (dark red)
// s = spike/plate accent     c = claw (cream)     h = horn
// f = feather accent

export function makePalette(color) {
  return {
    ".": null,
    o: shadeColor(color, -65),      // outline dark
    b: color,                         // base
    d: shadeColor(color, -30),        // dark shade
    l: shadeColor(color, 28),         // light
    u: shadeColor(color, 50),         // belly (lightest)
    w: "#f0ece0",                     // white
    p: "#0d0604",                     // pupil
    t: "#eadbaa",                     // teeth
    m: "#4a1010",                     // mouth
    c: "#d8c880",                     // claws
    s: shadeColor(color, 35),         // semi-light
    h: shadeColor(color, 60),         // highlight (brighter)
    f: shadeColor(color, -15),        // shadow
    g: shadeColor(color, 45),         // mid-highlight
    e: shadeColor(color, -45),        // deep shadow
  };
}

export function Sprite({ data, x, y, palette, flipX }) {
  const rects = [];
  let idx = 0;
  for (let r = 0; r < data.length; r++) {
    const row = data[r];
    for (let c = 0; c < row.length; c++) {
      const ch = row[c];
      const col = palette[ch];
      if (!col) continue;
      const px = flipX ? x + (row.length - 1 - c) : x + c;
      const py = y + r;
      // Main pixel
      rects.push(<rect key={idx++} x={px} y={py} width={1.06} height={1.06} rx={0.08} fill={col} />);
      // Highlight sub-pixel (top edge)
      if (ch !== 'o' && ch !== '.') {
        rects.push(<rect key={idx++} x={px + 0.05} y={py} width={0.95} height={0.35}
          fill={shadeColor(col, 18)} rx={0.06} opacity={0.5} />);
      }
      // Shadow sub-pixel (bottom edge)
      if (ch !== 'o' && ch !== '.') {
        rects.push(<rect key={idx++} x={px + 0.05} y={py + 0.7} width={0.95} height={0.36}
          fill={shadeColor(col, -15)} rx={0.06} opacity={0.35} />);
      }
    }
  }
  return <>{rects}</>;
}

// ============ HEAD SPRITES (facing right) ============
export const HEAD_SPRITES = {
  tyrant: [
    "....ooooooo...",
    "...ohlllllhoo.",
    "..ohlllllllhbo",
    "..ohlwwpllhbbo",
    "..ohlwwplfbbbo",
    ".ohbbbbbbfbbeo",
    ".ohbbbbbbfbbeo",
    ".obbbbbbffbbeo",
    ".ommmmmmmmmmmo",
    "..ooooooooooo.",
  ],
  spino: [
    "...oooooo........",
    "..ohlllhbo.......",
    ".ohlwwpllbooo....",
    ".ohlwwplfbbbbooo.",
    ".ohbbbbbbfbbbbbeo",
    ".obbbbbbbffbbbbeo",
    ".ommmmmmmmmmmmmmo",
    "..ooooooooooooooo",
  ],
  raptor: [
    ".....eeee....",
    "....oefbhfo..",
    "...ohllfbhfo.",
    "..ohlwwpfbbbo",
    "..ohlwwpfbbbo",
    "..ohbbbbbfbeo",
    "..ommmmmmmmoo",
    "...oooooooo..",
  ],
  sauropod: [
    "...ooooo.",
    "..ohlllho",
    "..ohwwpfo",
    "..ohbbfeo",
    "..ommmmmo",
    "...ooooo.",
  ],
  ceratopsian: [
    "hh.....hh.......",
    ".hh.s.hh........",
    "...shs..........",
    "..sssss.........",
    ".sssssss.ooooo..",
    "ssssssssohllhbo.",
    ".sssssssobwplfbo",
    "..sssssohbbbfeo.",
    "...sssobbbbfeo..",
    "....ssoommmmmoo.",
    "......ooooooo...",
  ],
  armored: [
    "....ssssss....",
    "...ssdsdsdss..",
    "..sssssssssso.",
    ".ohbbbbbbbbheo",
    ".ohlwwpbbbbheo",
    ".ohlwwpbbbfbeo",
    ".obbbbbbbbfbeo",
    ".ommmmmmmmmmoo",
    "..oooooooooo..",
  ],
  hadrosaur: [
    "....sss.........",
    "...sglgs........",
    "...sglgs........",
    "....soooo.......",
    ".....ohbboooooo.",
    "....ohbbbbbbbheo",
    "...ohlwwpbbbbheo",
    "...ohlwwpbbbfbeo",
    "..obbbbbbbbffbeo",
    "..ommmmmmmmmmmmo",
    "...ooooooooooo..",
  ],
  flyer: [
    "...ss...................",
    "..ssss..................",
    ".sslss..................",
    "sslssoooo...............",
    ".ssohllhbooooooo........",
    "..ohlwwpfbbbbbbbooo.....",
    "..ohbbbbbbbbbbbbbbboo...",
    "..ooooooooooooooooooooo.",
  ],
  marine: [
    "....oooooo.......",
    "...ohlllhbo......",
    "..ohlwwpfbboo....",
    "..ohlwwpffbbboo..",
    ".ohbbbbbbfbbbbbbo",
    ".obbbbbbbbbbbbbbbo",
    ".ommmmmmmmmmmmmmmo",
    "..oooooooooooooo..",
  ],
};

// Head origin offsets (where the neck attaches, from top-left of sprite)
export const HEAD_NECK_OFFSET = {
  tyrant: { x: 1, y: 6 },
  spino: { x: 1, y: 4 },
  raptor: { x: 2, y: 5 },
  sauropod: { x: 2, y: 3 },
  ceratopsian: { x: 10, y: 6 },
  armored: { x: 1, y: 4 },
  hadrosaur: { x: 4, y: 6 },
  flyer: { x: 3, y: 6 },
  marine: { x: 1, y: 4 },
};

// ============ BODY SPRITE (shared, 28x14) ============
export const BODY_SPRITE = [
  "..........ooooooooooo..........",
  ".......ooohllllllllhoooo.......",
  ".....oohhllllllllllllhhoo.....",
  "....ohhllllllllllllllllhho...",
  "...ohlllllllllllhhlllllllho..",
  "..ohlllllllhhhhhhhhllllllfeo.",
  "..ohlllhhhhhhhhhhhhhhhllffeo.",
  "..ohhhhhhhhhhhhhbbbbhhhhffeo.",
  "..ohhhhhhbbbbbbbbbbbbbbhffeo.",
  ".ohbbbbbbbbbbuuuuuuuuubbbfeo",
  ".ohbbbbbbuuuuuuguuuuuuubbfeo",
  ".ohbbbuuuuuuugggguuuuuuubfeo",
  "..obuuuuuuuuuuuuuuuuuuuufoo.",
  "...oouuuuuuuuuuuuuuuuuuoo...",
  ".....oouuuuuuuuuuuuuuoo.....",
  "........ooooooooooooooo.......",
];

// ============ LEG SPRITES ============
export const LEG_SPRITES = {
  bipedBig: [  // tyrant
    "ohho",
    "ohbo",
    "obbo",
    "obbfo",
    "obbeo",
    ".obfo",
    ".obeo",
    "obbbeo",
    "oocccoo",
  ],
  bipedFast: [  // raptor
    ".obo",
    ".obo",
    ".obbo",
    "..obo",
    "..obbo",
    "ooccoo",
  ],
  bipedHadro: [
    "obbo",
    "obbo",
    "obbo",
    ".obbo",
    ".obbo",
    "obbbbo",
    "ooooo",
  ],
  quadColumn: [  // sauropod/ceratopsian/armored front or back
    "ohbfo",
    "ohbfo",
    "ohbfo",
    "obfeo",
    "obfeo",
    "oooooo",
  ],
  wing: [
    "...oooooooooo",
    "..obbbbbbbbbo",
    ".obbbbbbbbboo",
    "obbbbbbbbbboo",
    "obbbbbbbbbbo.",
    ".obbbbbbbboo.",
    "..oooooooooo.",
  ],
  flipper: [
    "obbbbbbo",
    "obbbbbbo",
    ".oobbbo.",
    "...ooo..",
  ],
  armTiny: [  // T-Rex little arms
    "ob",
    "ob",
    "oc",
  ],
  armClawed: [  // raptor, spino, therizino
    ".ob.",
    ".ob.",
    "obbo",
    "ocbo",
    "occo",
  ],
  armMedium: [  // generic
    ".ob.",
    ".ob.",
    "obbo",
    "oboo",
  ],
};

// ============ DORSAL FEATURES ============
export function renderDorsal(family, spikes, armor, x, y, width, palette) {
  const parts = [];
  if (family === "spino") {
    // tall sail
    const sailH = 9 + Math.floor(spikes / 2);
    const sailData = [];
    for (let i = 0; i < sailH; i++) {
      const w = width - Math.floor(Math.abs(i - sailH / 2) * 1.2);
      const pad = Math.floor((width - w) / 2);
      const row = ".".repeat(pad) + (i === 0 ? "o".repeat(w) : "o" + "s".repeat(w - 2) + "o") + ".".repeat(pad);
      sailData.push(row.padEnd(width, "."));
    }
    parts.push(<Sprite key="sail" data={sailData} x={x} y={y - sailH} palette={palette} />);
  } else if (family === "armored" && spikes >= 6) {
    // stego plates
    const nPlates = 5;
    for (let i = 0; i < nPlates; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / nPlates);
      const plateData = [
        "..ooo..",
        ".olllo.",
        "olllllo",
        "oslslso",
        "oooooo.",
      ];
      parts.push(<Sprite key={`plate-${i}`} data={plateData} x={px} y={y - 5} palette={palette} />);
    }
  } else if (family === "armored") {
    // anky bumps
    for (let i = 0; i < 6; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / 6);
      parts.push(<Sprite key={`bump-${i}`} data={["ooo", "odlo", "oooo"]} x={px} y={y - 2} palette={palette} />);
    }
  } else if (family === "sauropod" && spikes > 4) {
    // amarga twin spines
    for (let i = 0; i < 5; i++) {
      const px = x + 5 + i * 3;
      parts.push(<rect key={`s-${i}`} x={px} y={y - 4} width={1.1} height={4} rx={0.2} fill={palette.o} />);
    }
  } else if (spikes > 4) {
    // generic spikes along back
    const n = Math.min(8, 3 + Math.floor(spikes / 1.5));
    for (let i = 0; i < n; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / n);
      const h = 1 + Math.floor(spikes / 3);
      parts.push(<Sprite key={`sp-${i}`} data={Array.from({ length: h }, (_, j) => (j === h - 1 ? "ooo" : "." + "o" + "."))} x={px} y={y - h} palette={palette} />);
    }
  }
  return parts;
}

// ============ TAIL ============
export function renderTail(family, power, length, startX, startY, palette, dorsalSpikes) {
  const thickness = 2 + Math.floor(power / 3);
  const tailLen = 10 + Math.floor(length * 1.5);
  const parts = [];

  // Curved tail using a pixel curve
  const points = [];
  for (let i = 0; i <= tailLen; i++) {
    const t = i / tailLen;
    let tx, ty;
    if (family === "sauropod") {
      // long, droops down at end
      tx = startX - i;
      ty = startY + Math.floor(t * t * 6);
    } else if (family === "marine") {
      tx = startX - i;
      ty = startY + Math.floor(Math.sin(t * 2) * 2);
    } else if (family === "flyer") {
      tx = startX - Math.floor(i * 0.4);
      ty = startY + Math.floor(t * 2);
      if (i > 6) break;
    } else {
      // biped/quad default: lifted, gently curved
      tx = startX - i;
      ty = startY - Math.floor(Math.sin(t * Math.PI) * 3);
    }
    points.push({ x: tx, y: ty });
  }

  // Draw tail segments
  points.forEach((pt, i) => {
    const t = i / points.length;
    const thick = family === "sauropod"
      ? Math.max(1, thickness - Math.floor(t * thickness))
      : family === "raptor"
        ? Math.max(1, thickness - Math.floor(t * 2))
        : thickness;
    for (let dy = 0; dy < thick; dy++) {
      const isEdge = dy === 0 || dy === thick - 1;
      parts.push(
        <rect key={`tail-${i}-${dy}`} x={pt.x} y={pt.y + dy} width={1.02} height={1.02}
          fill={isEdge ? palette.o : palette.b} rx={0.2} />
      );
    }
  });

  // Tail tip ornament
  const tip = points[points.length - 1];
  if (tip) {
    if (family === "armored" && dorsalSpikes >= 4) {
      // thagomizer - 4 spikes
      const thago = [
        "h.h.h.h",
        "h.h.h.h",
        "ooooooo",
      ];
      parts.push(<Sprite key="thago" data={thago} x={tip.x - 3} y={tip.y - 2} palette={palette} />);
    } else if (family === "armored") {
      // club
      const club = [
        ".ooo.",
        "odddo",
        "ohhdo",
        "odddo",
        ".ooo.",
      ];
      parts.push(<Sprite key="club" data={club} x={tip.x - 4} y={tip.y - 1} palette={palette} />);
    } else if (family === "marine") {
      // paddle
      const paddle = [
        "..oo.",
        ".obbo",
        "obbbbo",
        ".obbo",
        "..oo.",
      ];
      parts.push(<Sprite key="paddle" data={paddle} x={tip.x - 3} y={tip.y - 2} palette={palette} />);
    }
  }

  return parts;
}

// ============ TEETH in mouth ============
export function renderTeeth(family, count, sharp, mouthX, mouthY, mouthW, palette) {
  if (count === 0 || family === "flyer") return null;
  const teeth = [];
  const n = Math.min(mouthW - 1, Math.max(2, count + 2));
  const fangSize = sharp > 7 ? 2 : 1;
  for (let i = 0; i < n; i++) {
    const x = mouthX + Math.floor(i * (mouthW / n)) + 1;
    // upper teeth
    teeth.push(<rect key={`u-${i}`} x={x} y={mouthY} width={1} height={fangSize} fill={palette.t} rx={0.1} />);
    // lower teeth (alternating for sharpness)
    if (sharp > 5 && i % 2 === 1) {
      teeth.push(<rect key={`l-${i}`} x={x} y={mouthY + 2} width={1} height={fangSize} fill={palette.t} rx={0.1} />);
    }
  }
  return teeth;
}
